#!/bin/bash
# Usage:
#
#  coingecko.sh <WARNING_LEVEL> <COINGECKO_TOKEN_IDs...>
#
# Warning level indicates the thresholds of price change which you would like
# to receive notifications.

function _jq()
{
  jq -r "$@" 2> /dev/null
}

function alert_once()
{
  message="${1}"; shift
  state_filename="${1}"; shift

  if [[ "x$(cat "${state_filename}" 2> /dev/null)" != "x$(date '+%F')" ]]; then
    date '+%F' > "${state_filename}"
    notify-send --icon 'dialog-warning' "${message}"
  fi
}

function coingecko()
{
  url="${1}"; shift
  filename="${1}"; shift

  curl --silent "https://api.coingecko.com/api/v3/${url}" > "${filename}"
  fetch_error=$(_jq '.status.error_message' "${filename}")
  if [[ "x${fetch_error}" != 'xnull' && "x${fetch_error}" != 'x' ]]; then
    rm "${filename}"
    return 1
  fi
}

function get_token_list()
{
  filename="${1}"; shift

  if [[ ! -f "${filename}" ]]; then
    coingecko "coins/list?include_platform=false" "${filename}"
    return $?
  fi
}

function get_token_prices()
{
  filename="${1}"; shift
  tokens="${@}"

  coingecko "simple/price?ids=${tokens// /%2C}&vs_currencies=usd&include_24hr_change=true" "${filename}"
  return $?
}

function show_prices()
{
  results=''
  for token_id in "${@}"; do
    symbol=$(_jq ".[] | select(.id == \"${token_id}\") | .symbol" "${tokens_filename}" | tr '[:lower:]' '[:upper:]')
    price=$(_jq ".\"${token_id}\".usd" "${price_filename}")
    change=$(_jq ".\"${token_id}\".usd_24h_change | . * 100.0 + 0.5 | floor / 100.0" "${price_filename}")

    price_color='green'
    if [[ $(echo "${change} < 0" | bc) -eq 1 ]]; then
      price_color='red'
    fi

    change_color=${price_color}
    state_filename="${tokens_filename}_${token_id}_alert"
    if [[ $(echo "${change#-} > ${warninglevel}" | bc) -eq 1 ]]; then
      alert_once "Huge price change on ${symbol}" "${state_filename}"
      change_color='yellow'
      change="<b>${change}</b>"
    else 
      rm "${state_filename}" 2&> /dev/null
    fi 

    if [[ -n "${TOOLTIP:+is_set}" ]]; then
      results="$results\n${symbol} ${token_id} \$${price} (${change}%)"
    else
      results="$results ${symbol}: <span foreground=\"${price_color}\">\$${price}</span> <span foreground=\"${change_color}\">(${change}%)</span>"
    fi
  done
  echo -e "${results}"
}

warninglevel="${1}"; shift
tokens="${@}"
price_filename='/tmp/xfce-genmon-coingecko'
tokens_filename="${price_filename}_tokens"
trending_filename="${price_filename}_trending"

if (coingecko 'search/trending' "${trending_filename}"); then
  trending_tokens=$(_jq '.coins [].item .id' "${trending_filename}" | tr '\n' ' ')
fi

if ! (get_token_list "${tokens_filename}" && get_token_prices "${price_filename}" ${tokens} ${trending_tokens}); then
  echo "<txt>Error while fetching CoinGecko</txt>"
  exit 1
fi

echo -e \
  "<txt>$(show_prices ${tokens})</txt>" \
  "<txtclick>xdg-open 'https://www.coingecko.com/'</txtclick>" \
  "<tool>Click to visit CoinGecko\n\nTrending tokens:\n\n<span font-family=\"monospace\" allow-breaks=\"false\">$(TOOLTIP=1 show_prices ${trending_tokens} | column -t)</span>\n\n<small>(last update: $(date))</small></tool>"
