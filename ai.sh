#!/usr/bin/env bash
# ai.sh v1.0.0
# Created by Nathaniel Evry
# AI API wrapper script with enhanced usability and configurability

set -eo pipefail

# Typically, to override openAI_API settings, we need to use env variables.
# OPENAI_API_ENDPOINT="${OPENAI_API_ENDPOINT:-https://api.openai.com}"
# OPENAI_API_KEY="${OPENAI_API_KEY:-}"
# OPENAI_MAX_TOKENS="${OPENAI_MAX_TOKENS:-200}"

usage() {
	cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") -p 'it is a beautiful day to ai right?'
This script enables AI calls to servers using the OpenAI spec API via cli.

Options:
-p, --prompt [arg]                : Set the prompt text
-v, --verbose                     : Enable verbose output.
-t, --temperature [arg]           : Set the temperature parameter for AI generation.
-g, --guidance_scale [arg]        : Set the guidance scale to influence AI generation.
-k, --top_k [arg]                 : Set the top_k parameter for sampling outputs.
--min_p [arg]                     : Set the minimum probability threshold.
-P, --top_p [arg]                 : Set the top_p parameter for nucleus sampling.
-S, --Seed [arg]                  : Set the seed for random number generation.
-u, --repetition_penalty [arg]    : Set the repetition penalty to discourage repetition.
-m, --max_tokens [arg]            : Set the maximum number of tokens to generate.
--frequency_penalty [arg]         : Set the frequency penalty to discourage frequent tokens.
--repetition_penalty_range [arg]  : Set the range for repetition penalty application.
--top_a [arg]                     : Set the top_a parameter (custom usage not standard in AI models).
EOF
	exit
}

# Standard error handling function
raise_error() {
	echo -e "$1" >&2
	exit "${2:-1}"
}

parse_params() {
	input_text="$1"
	while :; do
		case "${1-}" in
		-p | --prompt)
			manual_input_text="${2-}"
			input_text="$manual_input_text"
			shift
			;;
		-v | --verbose)
			verbose=true
			;;
		-t | --temperature)
			temperature="${2-}"
			shift
			;;
		-g | --guidance_scale)
			guidance_scale="${2-}"
			shift
			;;
		-k | --top_k)
			top_k="${2-}"
			shift
			;;
		-P | --top_p)
			top_p="${2-}"
			shift
			;;
		-S | --Seed)
			Seed="${2-}"
			shift
			;;
		-u | --repetition_penalty)
			repetition_penalty="${2-}"
			shift
			;;
		-m | --max_tokens)
			# bughunt 'maxy'
			max_tokens="${2-}"
			shift
			;;
		--frequency_penalty)
			frequency_penalty="${2-}"
			shift
			;;
		--repetition_penalty_range)
			repetition_penalty_range="${2-}"
			shift
			;;
		--top_a)
			top_a="${2-}"
			shift
			;;
		-h | --help)
			usage
			;;
		-?*) raise_error "Try -h or --help; Unknown option: $1" ;;
		*) break ;;
		esac
		shift
	done
	# bughunt 'all parsed boss'
	return 0
}

# Function to handle API completions
query_completions() {
	promptText=${1:-$input_text}          # Default prompt if none provided
	url=${2:-'https://api.openai.com/v1'} # API URL, can be set to "anything"
	endpoint=${3:-'completions'}
	model=${4:-'gpt-3.5-turbo-0125'} # Specify the model here

	uri="${url}/${endpoint}"

	promptText=$(jq --raw-input --slurp --ascii-output . <<<"${promptText}")

	prompt_body='{
"prompt":'"$promptText"',
"temperature":'"$temperature"',
"model":"'"$model"'",
"guidance_scale":'"$guidance_scale"',
"max_tokens":'"$max_tokens"',
"seed":'"$Seed"',
"top_a":'"$top_a"',
"top_k":'"$top_k"',
"top_p":'"$top_p"',
"frequency_penalty":'"$frequency_penalty"',
"repetition_penalty_range":'"$repetition_penalty_range"',
"repetition_penalty":'"$repetition_penalty"'
}'

	if [[ $verbose ]]; then
		echo "$prompt_body"
	fi

	response=$(
		curl \
			-s \
			--url "${uri}" \
			-H "Content-Type: application/json" \
			-H "Authorization: Bearer $OPENAI_API_KEY" \
			-d "$prompt_body" | sed 's/\r//g'
	)

	# Extracting relevant parts
	completion_text=$(echo "$response" | jq -r '.choices[0].text')
	finish_reason=$(echo "$response" | jq -r '.choices[0].finish_reason')
	completion_tokens=$(echo "$response" | jq -r '.usage.completion_tokens')
	total_tokens=$(echo "$response" | jq -r '.usage.total_tokens')

	echo "verbose is $verbose"
	if [[ $verbose ]]; then
		echo "---"
		echo "$EPOCHSECONDS: ${completion_text}"
		echo "completion_tokens:${completion_tokens} / total_tokens:${total_tokens}: finish_reason:${finish_reason}"
	else
		echo "${completion_text}"
	fi
}

# Main function definition and execution
main() {
	local input_text='Default input text' verbose
	local temperature=0.7 guidance_scale=1 top_k=10 top_p=0.9
	local Seed=-1 repetition_penalty=1.2 max_tokens=200
	local frequency_penalty=1.02 repetition_penalty_range=2048 top_a=0

	parse_params "$@"
	query_completions "$input_text"
}

main "$@"
