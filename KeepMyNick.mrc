;****************************************************************
;
; KeepMyNick ver 1.5 by Czuz (https://github.com/Czuz)
; To install just type: /load -rs KeepMyNick.mrc
;
;****************************************************************
;
; Help:
; KEEPNICK
; Syntax: /keepnick [<nick>] [<network>|default]
; Assigns <nick> to <network> (Or current network.) W/o argument
; disables grabbing until reconnection.
;
; LISTNICK
; Syntax: /listnick [-all]
; Displays list of nicks.
;
; DELNICK
; Syntax: /delnick [<network>|default]
; Remove nick associated with <network> (Or current network) from
; list
;
;****************************************************************
; ChangeLog:
; ver 1.5 (08.05.2021)
; - published on GitHub
; ver 1.4 (23.03.2005)
; - better handling of nick collisions on IRCnet
; ver 1.3 (15.03.2005)
; - new download link
; - better handling of ERR_RESTRICTED on IRCnet
; ver 1.2 (28.08.2004)
; - new download link
; ver 1.1 (04.06.2004)
; - spelling checked
; - fixed handling of raw events
; - default nick
; - /keepnick <nick> default, /delnick default
; - some GUI changes
; ver 1.0 (30.05.2004)
; - setup dialog (Commands->KeepMyNick v1.0)
; - minor changes in functions
; - extended syntax of commands
; - configurable timer delay
; ver 1.0-pre3 (13.05.2004)
; - added support for raw events: 
;   ERR_ERRONEUSNICKNAME, ERR_NICKNAMEINUSE, ERR_UNAVAILRESOURCE and ERR_RESTRICTED
; ver 1.0-pre2 (25.12.2003)
; - fixed disappearing timer bug
; - $comchan() instead of $ial()
; - minor bugs fixed
; ver 1.0-pre1 (22.12.2003)
; - keeping different nicks in multi-server mode
; - /keepnick, /listnick and /delnick commands
; - saving settings to file on exit and reading them on first connect
; - three states of nick grabbing:
;   0 - disabled
;   1 - passive (on events only, when we are on the same channel as nickstealer)
;   2 - active  (periodically nick checking with timer)
;
; ver 0.9 (a long time ago)
; - simple on-event nick keeping for a single network
;
;****************************************************************

;--------------------------[ E V E N T S ]--------------------------

on *:LOAD: {
  %KMN.Version = KeepMyNick v1.5
  echo -st [KeepMyNick] Loading %KMN.Version ...
  if ($version < 6.03) {
    echo -st [KeepMyNick] Script NOT installed. Upgrade your mIRC version to 6.03+.
    timer 1 2 unload -rs " $+ $script $+ "
    halt
  }
  if (%KeepMyNickDelay) {
    %KMN.Delay = %KeepMyNickDelay
    unset %KeepMyNickDelay
  }
  else { %KMN.Delay = 10 }
  if ($hget(MyNicks) == $null) { 
    hmake MyNicks 10
    if ($scon(0) > 0 && $isfile(KeepMyNick.dat)) {
      hload -b MyNicks KeepMyNick.dat
    }
  }
  echo -st [KeepMyNick] - DONE! -
  echo -st [KeepMyNick]
  echo -st [KeepMyNick] Available commands:
  echo -st [KeepMyNick] /keepnick [<nick>] [<network>|default]
  echo -st [KeepMyNick] /listnick [-all]
  echo -st [KeepMyNick] /delnick [<network>|default]
  echo -st [KeepMyNick]
  echo -st [KeepMyNick] For graphic setup, go to  Menu->Commands-> $+ %KMN.Version
}

on *:UNLOAD: {
  .timerKeepMyNick off
  if ($hget(MyNicks)) { 
    hsave -ob MyNicks KeepMyNick.dat
    hfree MyNicks 
  }
  unset %KMN.Delay
  unset %KMN.Version
  unset %KMN.Default
  unset %KMN.Options
  echo -st [KeepMyNick] Bye...
}

on *:CONNECT: {
  if ($scon(0) == 1) {
    if ($isfile(KeepMyNick.dat)) { 
      if ($hget(MyNicks) == $null) { hmake MyNicks 10 }
      hload -b MyNicks KeepMyNick.dat
    }
  }
  if ($KMN.MyNick) { KMN.ChangeNickState 2 }
  elseif (%KMN.Options == KMN.AddDef) { hadd -m MyNicks $KMN.FindNetwork 2 %KMN.Default }
  elseif (%KMN.Options == KMN.KeepDef) { hadd -m MyNicks $KMN.FindNetwork 2 %KMN.Default 1 }
  KMN.GetMyNick
}

on *:DISCONNECT: {
  if ($nick == $me && $KMN.NickIsHidden) { hdel MyNicks $KMN.FindNetwork }
}


on *:EXIT: {
  if ($hget(MyNicks)) { 
    hsave -ob MyNicks KeepMyNick.dat
    hfree MyNicks
  }
}

on *:KICK:#: {
  if ($nick == $me || $nick == $KMN.MyNick) {
    if ( $KMN.NickState > 0 ) {
      KMN.ChangeNickState 2
    }
  }
}

on *:PART:#: {
  if ($nick == $me || $nick == $KMN.MyNick) {
    if ( $KMN.NickState > 0 ) {
      KMN.ChangeNickState 2
    }
  }
}

on *:NICK: {
  if ($nick != $me && $nick == $KMN.MyNick) {
    if ( $KMN.NickState > 0 ) {
      tnick $KMN.MyNick
    }
  }
  elseif ($nick == $me && $nick == $KMN.MyNick && $KMN.NickState > 0) {
    echo -at [KeepMyNick] Disabled for network $KMN.FindNetwork
    KMN.ChangeNickState 0
  }
}

on *:QUIT: {
  if ($nick != $me && $nick == $KMN.MyNick) {
    if ( $KMN.NickState > 0 ) {
      tnick $KMN.MyNick
    }
  }
}

;----------------------[ R A W   E V E N T S ]----------------------

; ERR_ERRONEUSNICKNAME
raw 432:*: {
  if ($KMN.MyNick && $2 == $KMN.MyNick) {
    echo -st [KeepMyNick] $2 - Erroneous Nickname
    echo -st [KeepMyNick] Disabling for network $KMN.FindNetwork
    KMN.ChangeNickState 0
    halt
  }
}

; ERR_NICKNAMEINUSE
raw 433:*: {
  if ($KMN.MyNick && $2 == $KMN.MyNick) {
    halt
  }
}

; ERR_UNAVAILRESOURCE
raw 437:*: {
  if ($KMN.MyNick && $2 == $KMN.MyNick) {
    halt
  }
}

; ERR_RESTRICTED
raw 484:*: {
  if ($KMN.FindNetwork != IRCnet || $left($me, 1) !isin 0123456789) {
    if ($KMN.NickState && $KMN.NickState != 0) {
      echo -st [KeepMyNick] Your connection is restricted!
      echo -st [KeepMyNick] Disabling for network $KMN.FindNetwork
      KMN.ChangeNickState 0
      halt
    }
  }
}

;---------------------[From OmenServe 1.42-b08]---------------------
; This should compensate for NewNet's lack of $network issues
alias KMN.FindNetwork {
  if ( $network != $null ) { return $network }
  if ( $server == irc.aohell.org ) { return NewNet }
  if ( $server == irc.d0t.net ) { return NewNet }
  if ( $server == irc.dividedspace.com ) { return NewNet }
  if ( $server == irc.dragonskeep.com ) { return NewNet }
  if ( $server == irc.eskimo.com ) { return NewNet }
  if ( $server == irc.feartomorrow.com ) { return NewNet }
  if ( $server == irc.firex.org ) { return NewNet }
  if ( $server == irc.josephbarnhart.net ) { return NewNet }
  if ( $server == irc.linux-friendly-56k.com ) { return NewNet }
  if ( $server == irc.phantomshitter.net ) { return NewNet }
  if ( $server == irc.sweatnet.net ) { return NewNet }
  if ( $server == irc.moo.me.uk ) { return NewNet }
  if ( $server == olympic.olympos-net.gr ) { return NewNet }
  if ( $server != $null ) { return $server }
  return Offline
}
;------------------------------[END]--------------------------------
;-----------------------[ F U N C T I O N S ]-----------------------
alias KMN.MyNick {
  if ($1) {
    return $gettok($hget(MyNicks, $1), 2, 32)
  }
  else {
    return $gettok($hget(MyNicks, $KMN.FindNetwork), 2, 32)
  }
}

alias KMN.NickState {
  if ($1) {
    return $gettok($hget(MyNicks, $1), 1, 32)
  }
  else {
    return $gettok($hget(MyNicks, $KMN.FindNetwork), 1, 32)
  }
}

alias KMN.NickIsHidden {
  if ($1) {
    return $gettok($hget(MyNicks, $1), 3, 32)
  }
  else {
    return $gettok($hget(MyNicks, $KMN.FindNetwork), 3, 32)
  }
}

alias KMN.ChangeNickState {
  hadd -m MyNicks $KMN.FindNetwork $1 $mid($hget(MyNicks, $KMN.FindNetwork), 3)
}

alias KMN.GetMyNick {
  var %currentserver = $cid
  var %i = 1
  while ($scon(%i)) {
    scid $scon(%i)
    if ( $server != $null && $me != $KMN.MyNick && $KMN.NickState > 1 ) {
      if ($comchan($KMN.MyNick,0) != 0) {
        KMN.ChangeNickState 1
      }
      else {
        tnick $KMN.MyNick
      }
    }
    inc %i
  }
  scid %currentserver
  .timerKeepMyNick -i 1 %KMN.Delay KMN.GetMyNick
}

alias KMN.GetNetworkFromLine {
  return $gettok($did(KMN.Setup, 11).seltext, 2, $asc(@))
}

alias KMN.CheckDelay {
  if ($1 !isnum) { return 10 }
  elseif ($1 < 5 ) { return 5 }
  elseif ($1 > 600) { return 600 }
  else { return $1 }
}

alias KMN.UpdateNicks {
  var %currentserver = $cid
  var %i = 1
  while ($scon(%i)) {
    scid $scon(%i)
    if ((!$KMN.MyNick || $KMN.NickIsHidden) && %KMN.Options == KMN.AddDef) { 
      hadd -m MyNicks $KMN.FindNetwork 2 %KMN.Default
    }
    elseif ((!$KMN.MyNick || $KMN.NickIsHidden) && %KMN.Options == KMN.KeepDef) {
      hadd -m MyNicks $KMN.FindNetwork 2 %KMN.Default 1
    }
    elseif ($KMN.NickIsHidden && %KMN.Options != KMN.KeepDef) {
      hdel MyNicks $KMN.FindNetwork
    }
    inc %i
  }
  scid %currentserver
  KMN.GetMyNick
}

alias KMN.DialogDelNick {
  if ($1) {
    hdel MyNicks $1
    did -d KMN.Setup 11 $did(KMN.Setup, 11, 1).sel
  }
}

alias KMN.DialogAddNick {
  if ($1) { hdel MyNicks $1 }
  hadd -m MyNicks $did(KMN.AddEdit,101) 2 $did(KMN.AddEdit,102)
  if ($1) { did -o KMN.Setup 11 $did(KMN.Setup, 11, 1).sel $did(KMN.AddEdit,102) $+ @ $+ $did(KMN.AddEdit,101) }
  else { did -a KMN.Setup 11 $did(KMN.AddEdit,102) $+ @ $+ $did(KMN.AddEdit,101) }
  KMN.GetMyNick
}

alias KMN.DialogCheckBox {
  if ($1 == 23) { var %i = 24 }
  else { var %i = 23 }
  if ($did(KMN.setup, $1).state == 0) { 
    if ($1 == 23) { var %i = 24 }
    else { var %i = 23 }
    %KMN.Options = $null
    did -e KMN.setup %i
  }
  else {
    if ($1 == 23) { 
      var %i = 24
      %KMN.Options = KMN.AddDef
    }
    else {
      var %i = 23
      %KMN.Options = KMN.KeepDef
    }
    did -b KMN.setup %i
  }
}
;------------------------[ C O M M A N D S ]------------------------
alias keepnick {
  if ($2 == $null && $server == $null) {
    echo -st [KeepMyNick] Connect to a server first.
    halt
  }
  if ($1) { 
    if ($2 && $2 != default) { hadd -m MyNicks $2 2 $1 }
    elseif ($2 && $2 == default) { %KMN.Default = $1 | %KMN.Options = KMN.KeepDef }
    else { hadd -m MyNicks $KMN.FindNetwork 2 $1 }
    KMN.GetMyNick
  }
  else { 
    echo -st [KeepMyNick] Disabled for network $KMN.FindNetwork
    KMN.ChangeNickState 0
  }
}

alias listnick {
  echo -at [KeepMyNick] List of nicks:
  var %i = 1
  if ($1 == -all) {
    var %max.servers = $hget(MyNicks,0).item
    while (%i <= %max.servers) {
      var %tmpserver = $hget(MyNicks,%i).item
      if (!$KMN.NickIsHidden(%tmpserver)) {
        echo -at [KeepMyNick] $KMN.MyNick(%tmpserver) $+ @ $+ %tmpserver
      }
      inc %i
    }
  }
  else {
    var %currentserver = $cid
    while ($scon(%i)) {
      scid $scon(%i)
      if ($server && $KMN.MyNick && !$KMN.NickIsHidden) {
        echo -at [KeepMyNick] $KMN.MyNick $+ @ $+ $KMN.FindNetwork $iif(($KMN.NickState == 0),(disabled),(enabled))
      }
      inc %i
    }
    scid %currentserver
  }
}

alias delnick {
  if ($1 && $1 == default && %KMN.Options = KMN.KeepDef) {
    echo -st [KeepMyNick] Default nick disabled.
    %KMN.Options = $null
    KMN.UpdateNicks
  }
  elseif ($1 && $KMN.MyNick($1)) {
    echo -st [KeepMyNick] Nick for $1 deleted.
    hdel MyNicks $1
  }
  elseif ($1 == $null && $KMN.MyNick) {
    echo -st [KeepMyNick] Nick for $KMN.FindNetwork deleted.
    hdel MyNicks $KMN.FindNetwork
  }
  else { echo -st [KeepMyNick] No nick for that network. }
}

;----------------------------[ M E N U ]----------------------------
menu menubar {
  %KMN.Version { dialog -m KMN.setup KMN.SetupDialog }
}
;-------------------------[ D I A L O G S ]-------------------------
dialog -l KMN.SetupDialog {
  title %KMN.Version
  size -1 -1 210 155
  option dbu

  box "Setup", 10, 2 2 206 130
  list 11, 30 19 165 65, size, sort, vsbar
  button "Add", 12, 6 19 20 15
  button "Edit", 13, 6 36 20 15
  button "Del", 14, 6 53 20 15
  text "Nicks:", 15, 31 10 25 8
  text %KMN.Version by Czuz, 16, 125 90 80 8
  link "Latest version", 17, 125 98 80 8

  text "Timer delay:", 18, 30 87 30 8
  edit %KMN.Delay, 19, 63 86 35 10, right, limit 4
  text "sec.", 20, 100 87 10 8
  text "Default nick:", 21, 30 99 30 8
  edit %KMN.Default, 22, 63 98 35 10, right
  check "Add default nick to undefined networks", 23, 30 111 200 8
  check "Keep default nick on undefined networks", 24, 30 121 200 8

  button "Done", 99, 85 135 40 15, ok
}

dialog -l KMN.AddEditDialog {
  title "KeepMyNick - Add/Edit"
  size -1 -1 145 60
  option dbu

  combo 101, 15 15 60 10, edit, vsbar, drop
  edit "", 102, 90 15 40 10
  text "Network:", 103, 17 5 58 8
  text "Nick:", 104, 92 5 38 8

  button "Ok", 109, 30 35 30 15, ok
  button "Cancel", 110, 85 35 30 15, cancel
}

on *:dialog:KMN.setup:init:0 {
  var %max.servers = $hget(MyNicks,0).item
  var %i = 1
  while (%i <= %max.servers) {
    var %tmpserver = $hget(MyNicks,%i).item
    if (!$KMN.NickIsHidden(%tmpserver)) {
      did -a KMN.setup 11 $KMN.MyNick(%tmpserver) $+ @ $+ %tmpserver
    }
    inc %i
  }
  if (%KMN.Options == KMN.AddDef) { did -c KMN.setup 23 | did -b KMN.setup 24 }
  elseif (%KMN.Options == KMN.KeepDef) { did -c KMN.setup 24 | did -b KMN.setup 23 }
}

on *:dialog:KMN.setup:sclick:12 { 
  did -u KMN.Setup 11 $did(KMN.Setup, 11, 1).sel
  $dialog(KMN.AddEdit, KMN.AddEditDialog, -4)
}

on *:dialog:KMN.setup:sclick:13 { $dialog(KMN.AddEdit, KMN.AddEditDialog, -4) }
on *:dialog:KMN.setup:sclick:14 { $KMN.DialogDelNick($KMN.GetNetworkFromLine) }
on *:dialog:KMN.setup:sclick:17 { run https://github.com/Czuz/KeepMyNick }
on *:dialog:KMN.setup:edit:19 { %KMN.Delay = $KMN.CheckDelay($did(KMN.setup,19)) }
on *:dialog:KMN.setup:edit:22 { %KMN.Default = $did(KMN.setup, 22)) }
on *:dialog:KMN.setup:sclick:23,24 { $KMN.DialogCheckBox($did) }
on *:dialog:KMN.setup:sclick:99 { $KMN.UpdateNicks }

on *:dialog:KMN.AddEdit:init:0 {
  var %sel.network = $KMN.GetNetworkFromLine
  if (%sel.network) { did -a KMN.AddEdit 101 %sel.network }

  var %currentserver = $cid
  var %i = 1
  while ($scon(%i)) {
    scid $scon(%i)
    if ($server != $null && $network != $did(KMN.AddEdit,101,1)) {
      did -a KMN.AddEdit 101 $KMN.FindNetwork
    }
    inc %i
  }
  scid %currentserver

  did -c KMN.AddEdit 101 1
  did -i KMN.AddEdit 102 1 $KMN.MyNick($did(KMN.AddEdit,101,1))
}

on *:dialog:KMN.AddEdit:sclick:109 { $KMN.DialogAddNick($KMN.GetNetworkFromLine) }
;----------------------------[ E N D ]------------------------------
