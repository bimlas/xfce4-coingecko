# XFCE CoinGecko

[Generic Monitor (Genmon)](https://docs.xfce.org/panel-plugins/xfce4-genmon-plugin) plugin that shows the prices of your favorite and trending cryptocurrency tokens via fetching [CoinGecko](https://coingecko.com/) API.

![screenshot](https://i.imgur.com/jwftW6m.png[])

Features:

- Click on the widget to visit CoinGecko site
- Hover over the widget to view trending tokens
- Get system notification from tokens having huge price change

https://github.com/bimlas/xfce4-coingecko (**please star if you like the plugin**)

## Usage

```
$ xfce4-coingecko.sh <warnlevel> <token1> <token2> ...
```

- `<warnlevel>`
  - The minimum daily price change expressed as a percentage for which you want to receive notifications (set it to a high value to disable)
- `<token>`
  - CoinGecko API ID of the token (from the "Info" box of it)

Because the list of the tokens could be long, it's suggested to create a "wrapper" shell script, for example `xfce4-coingecko-wrapper.sh`:

```
#!/bin/sh
/path/to/xfce4-coingecko.sh 20 bitcoin ethereum matic-network
```

Don't forget to make it executable via `chmod +x xfce4-coingecko-wrapper.sh`.

## Adding Genmon widget

- First you have to install `xfce4-genmon-plugin` package if it is not on your system
- Add the monitor to the panel
  - Right click on the panel
  - Select _Panel -> Add new items_
  - Add _Generic Monitor_ plugin
- Set up the generic monitor to use with this script
  - Right click on the newly added generic monitor -> _Properties_
  - Command: `/path/to/xfce4-coingecko-wrapper.sh`
  - Uncheck the checkbox of _Label_
  - Set _Period_ to at least `30` seconds
    - Do not set it to lower value because you would reach rate-limit of the API
