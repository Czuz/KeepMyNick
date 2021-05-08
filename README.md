# KeepMyNick
Have you ever connected to IRC and discovered that your nick is taken by someone else or not available? 

This mIRC script helps to address this issue and to automatically reclaim your nick once it's available. You can configure different nicks for different networks.

Nick change could be triggered by several server events or by the timer. Actual mode depends on whether you are on a common channel with the person that uses your nick or not.

## Download
Download the KeepMyNick.mrc from [here](https://raw.githubusercontent.com/Czuz/KeepMyNick/main/KeepMyNick.mrc) (right click and save).

## Install
To install place KeepMyNick.mrc script in mIRC directory (e.g. C:\Program Files\mIRC\), open mIRC and type: 
```
/load -rs KeepMyNick.mrc
```

## Help
### Syntax:
* KEEPNICK - Assigns \<nick\> to \<network\> (or current network.) W/o argument disables grabbing until reconnection.
```
/keepnick [<nick>] [<network>|default]
```

* LISTNICK - Displays list of nicks: current network or all networks.
```
/listnick [-all]
```

* DELNICK - Removes nick associated with \<network\> (or current network) from list
```
/delnick [<network>|default]
```

### GUI
For graphic setup, open mIRC and go to  Menu->Commands->KeepMyNick v1.5

## How to remove
Open mIRC and type: 
```
/unload -rs KeepMyNick.mrc
```

## ChangeLog
There are no current plans for further development.

For the complete ChangeLog please refer to the [header section](https://github.com/Czuz/KeepMyNick/blob/main/KeepMyNick.mrc#L24) of the script.
