#!/usr/bin/env bash

# This plugin uses the Coingecko public API: https://www.coingecko.com/en/api

CWD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CWD/tmux.sh"

CRYPTO_CURRENCY=$(get_tmux_option @kripto_currency "usd")
CRYPTO_CURRENCY_SYMBOL=$(get_tmux_option @kripto_currency_symbol "$")
CRYPTO_ID=$(get_tmux_option @kripto_id "bitcoin")
CRYPTO_TTL=$(get_tmux_option @kripto_ttl 600)
CRYPTO_ICON=$(get_tmux_option @kripto_icon '¤ ')
CRYPTO_ICON_HIDE=$(get_tmux_option @kripto_icon_hide 'false')
CRYPTO_ROUND=$(get_tmux_option @kripto_round 'false')

cache_file=~/.tmux-kripto
cache_ttl=$CRYPTO_TTL

if [[ $CRYPTO_ICON_HIDE == 'true' ]]; then
	ICON=''
else
	ICON=$CRYPTO_ICON
fi

if [[ -f "$cache_file" ]]; then
	NOW=$(date +%s)
	MOD=$(date -r "$cache_file" +%s)
	if [[ $((NOW - MOD)) -gt $cache_ttl ]]; then
		rm "$cache_file"
	fi
fi

if [[ ! -f "$cache_file" ]]; then
	RESPONSE=$(curl --silent -X 'GET' https://api.coingecko.com/api/v3/coins/markets?vs_currency="${CRYPTO_CURRENCY}"\&ids="${CRYPTO_ID}")

	PRICE=$(echo "$RESPONSE" | jq '.[].current_price')

	if [[ $CRYPTO_ROUND == 'true' ]]; then
		PRICE=$(printf "%.2f" "$PRICE")
	fi

	echo "${ICON}${PRICE}${CRYPTO_CURRENCY_SYMBOL}" >"$cache_file"
fi

cat "$cache_file"
