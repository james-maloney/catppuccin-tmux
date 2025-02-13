show_meetings() {
  local index=$1
  local icon
  local color
  local result
  local text
  local module
  icon="$(get_tmux_option "@catppuccin_meetings_icon" "")"
  color="$(get_tmux_option "@catppuccin_meetings_color" "$thm_blue")"
  result="$(main)"
  text="$(get_tmux_option "@catppuccin_meetings_text" "$result")"
  module=$( build_status_module "$index" "$icon" "$color" "$text" )
  echo "$module"
}

ALERT_IF_IN_NEXT_MINUTES=30
ALERT_POPUP_BEFORE_SECONDS=30
NERD_FONT_FREE="󱁕"
NERD_FONT_MEETING="󰤙"

get_attendees() {
	attendees=$(
	icalBuddy \
		--includeEventProps "attendees" \
		--propertyOrder "datetime,title" \
		--noCalendarNames \
		--dateFormat "%A" \
		--includeOnlyEventsFromNowOn \
		--limitItems 1 \
		--excludeAllDayEvents \
		--separateByDate \
		--excludeEndDates \
		--bullet "" \
		--excludeCals "Vacation/PTO" \
		eventsToday)
}

parse_attendees() {
	attendees_array=()
	for line in $attendees; do
		attendees_array+=("$line")
	done
	number_of_attendees=$((${#attendees_array[@]}-3))
}

get_next_meeting() {
	next_meeting=$(icalBuddy \
		--includeEventProps "title,datetime" \
		--propertyOrder "datetime,title" \
		--noCalendarNames \
		--dateFormat "%A" \
		--includeOnlyEventsFromNowOn \
		--limitItems 1 \
		--excludeAllDayEvents \
		--separateByDate \
		--bullet "" \
		--excludeCals "Vacation/PTO" \
		eventsToday)
}

get_next_next_meeting() {
	end_timestamp=$(date +"%Y-%m-%d ${end_time}:01 %z")
	tonight=$(date +"%Y-%m-%d 23:59:00 %z")
	next_next_meeting=$(
	icalBuddy \
		--includeEventProps "title,datetime" \
		--propertyOrder "datetime,title" \
		--noCalendarNames \
		--dateFormat "%A" \
		--limitItems 1 \
		--excludeAllDayEvents \
		--separateByDate \
		--bullet "" \
		--excludeCals "Vacation/PTO" \
		eventsFrom:"${end_timestamp}" to:"${tonight}")
}

# parse_result() {
# 	array=()
# 	for line in $1; do
# 		array+=("$line")
# 	done
# 	time="${array[2]} ${array[3]}"
# 	end_time="${array[4]} ${array[5]}"
# 	title="${array[*]:5:30}"
# }

parse_result() {
    IFS=$'\n' # Set Internal Field Separator to newline to read lines
    local input="$1"
    local -a lines=() # Declare an array to hold lines
    local line

    # Read lines from input
    while IFS= read -r line; do
        lines+=("$line")
    done <<< "$input"


  # TODO make a better parser

    local time_range="${lines[3]}" # Assuming the time range is on the third line
    title="${lines[4]}" # Assuming the title is on the fourth line, indented

    time=$(echo "$time_range" | awk -F' - ' '{print $1}')
    end_time=$(echo "$time_range" | awk -F' - ' '{print $2}')
}

calculate_times(){
  epoc_meeting=$(date -j -f "%Y-%m-%d %H:%M %p" "$(date +%Y-%m-%d) $time" +%s)
	epoc_now=$(date +%s)
	epoc_diff=$((epoc_meeting - epoc_now))
	minutes_till_meeting=$((epoc_diff/60))
}

display_popup() {
	tmux display-popup \
		-S "fg=#eba0ac" \
		-w50% \
		-h50% \
		-d '#{pane_current_path}' \
		-T meeting \
		icalBuddy \
			--propertyOrder "datetime,title" \
			--noCalendarNames \
			--formatOutput \
			--includeEventProps "title,datetime,notes,url,attendees" \
			--includeOnlyEventsFromNowOn \
			--limitItems 1 \
			--excludeAllDayEvents \
			--excludeCals "training" \
			eventsToday
}

print_tmux_status() {
	if [[ $minutes_till_meeting -lt $ALERT_IF_IN_NEXT_MINUTES \
		&& $minutes_till_meeting -gt -60 ]]; then
		echo "$NERD_FONT_MEETING \
			$time $title ($minutes_till_meeting minutes)"
	else
		echo "$NERD_FONT_FREE"
	fi

	if [[ $epoc_diff -gt $ALERT_POPUP_BEFORE_SECONDS && epoc_diff -lt $ALERT_POPUP_BEFORE_SECONDS+10 ]]; then
		display_popup
	fi
}

main() {
	get_attendees
	parse_attendees
	get_next_meeting
	parse_result "$next_meeting"
	calculate_times
  print_tmux_status
	# if [[ "$next_meeting" != "" && $number_of_attendees -lt 2 ]]; then
	# 	get_next_next_meeting
	# 	parse_result "$next_next_meeting"
	# 	calculate_times
	# fi
}
