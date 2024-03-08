show_pomo() {
  local index=$1
  local icon="$(get_tmux_option "@catppuccin_test_icon" "")"
  local color="$(get_tmux_option "@catppuccin_test_color" "$thm_orange")"

  local module=$( build_status_module "$index" "$icon" "$color" "#{pomodoro_status}" )

  echo "$module"
}
