override_git_prompt_colors() {
  GIT_PROMPT_THEME_NAME="Custom"

  GIT_DUET_INITIALS="\$(echo \$(git config --get-regexp ^git-together\.active | sed -e 's/^.*active //') | sed -e 's/ /+/')"
  GIT_PAIR=${GIT_DUET_INITIALS:-`git config user.initials | sed 's% %+%'`}

  DateTime="\$(date +'%Y-%m-%d %H:%M')"
  CfTarget="\$(cf-target)"
  GoBoshTarget="\$(gobosh_target_prompt)"
  Ochre="\033[38;5;95m"
  GIT_PROMPT_START_USER="\n${Ochre}bosh: ${GoBoshTarget} | cf: ${CfTarget} (\h) ${ResetColor}\n${Yellow}${PathShort}${ResetColor}"
  GIT_PROMPT_END_USER=" ${Cyan}${GIT_PAIR}${ResetColor}\n$ "
  GIT_PROMPT_END_ROOT="\n# "

  GIT_PROMPT_PREFIX="|"
  GIT_PROMPT_SUFFIX="|"
  GIT_PROMPT_SEPARATOR=" "

  #GIT_PROMPT_BRANCH="${Magenta}"
  GIT_PROMPT_STAGED="${Green}S:"
  GIT_PROMPT_CONFLICTS="${Red}C:"
  GIT_PROMPT_CHANGED="${Blue}U:"
  GIT_PROMPT_UNTRACKED="${Red}?:"
}

gobosh_target_prompt() {
  basename "${BOSH_ENV}"
}

# load the theme
reload_git_prompt_colors "Custom"
