# Devops-zsh
# by Ricardo Hincapie and Sergi Barroso
# https://github.com/ricarhincapie/devops-zsh
# MIT License

k8s_info() {
  if [ ! -z ${KUBECONFIG} ]; then
    k8s_context=$(awk '/current-context/{print $2}' $KUBECONFIG)
  elif [ -f "$HOME/.kube/config" ]; then
    if [[ $SENPAI_SHOW_AWS == true ]]; then # We bring the aws context format
      k8s_context=$(awk '/current-context/{print $2}' $HOME/.kube/config | awk -F"/" '{print $2}')
    else # We bring gcp context format
      k8s_context=$(awk '/current-context/{print $2}' $HOME/.kube/config | awk -F"_" '{print $4}')
    fi
  fi
  if [ ! -z ${k8s_context} ]; then
    echo " %F${darkgreen}⎈:${k8s_context}%f"
  fi
}


k8_namespace() {
  k8_namespace=""
  command -v kubectl >/dev/null 2>&1 && k8_namespace=$(kubectl config get-contexts --no-headers | grep '*' | grep -Eo '\S+$')
  echo " ${brown}ns:${k8_namespace}%f"
}


prompt_senpai_git() {
  senpai_git=""
  git rev-parse --abbrev-ref HEAD>/dev/null 2>/dev/null && senpai_git=$(git rev-parse --abbrev-ref HEAD)
  echo " ${darkred}(${senpai_git})%f"
}

aws_info() {
  if [ ! -z ${AWS_PROFILE} ]; then
    echo " ${yellow}ⓦ ${AWS_PROFILE}%f"
  elif [ ! -z ${AWS_DEFAULT_PROFILE} ]; then
    echo " ${yellow}* ${AWS_DEFAULT_PROFILE}%f"
  fi
}

azure_info() {
  if [ -f "$HOME/.azure/config" ]; then
    azure_cloud=$(awk '/name/{print tolower($3)}' $HOME/.azure/config)
    if [ ! -z ${azure_cloud} ]; then
      echo " ${blue}ⓐ ${azure_cloud}%f"
    fi
  fi
}

gcp_info() {
  if [ -f "$HOME/.config/gcloud/active_config" ]; then
    gcp_profile=$(cat $HOME/.config/gcloud/active_config)
    gcp_project=$(awk '/project/{print $3}' $HOME/.config/gcloud/configurations/config_$gcp_profile)
    if [ ! -z ${gcp_project} ]; then
      echo " ${darkgreen}ⓖ ${gcp_project}%f"
    fi
  fi
}

define_var() {
  local varname="$1"
  typeset -p "$varname" > /dev/null 2>&1
}

set_default() {
  local varname="$1"
  local default_value="$2"
  define_var "$varname"  || typeset -g "$varname"="$default_value"
}

#prompt_senpai_git() {
#  [[ -n ${git_info} ]] && print -n " ${(e)git_info[prompt]}"
#}

prompt_senpai_virtualenv() {
  [[ -n ${VIRTUAL_ENV} ]] && print -n " (%F{blue}${VIRTUAL_ENV:t}%f)"
}

prompt_senpai_precmd() {
  (( ${+functions[git-info]} )) && git-info
}

prompt_senpai_time() {
  print -n "[${white}%*] "
}

prompt_senpai_setup() {

  # Set default values
  [[ -n ${VIRTUAL_ENV} ]] && export VIRTUAL_ENV_DISABLE_PROMPT=1
  set_default SENPAI_THEME_DARK true
  set_default SENPAI_SHOW_TIME  true
  set_default SENPAI_SHOW_USER  false
  set_default SENPAI_SHOW_PATH  true
  set_default SENPAI_SHOW_GIT   false
  set_default SENPAI_SHOW_K8S   true
  set_default SENPAI_SHOW_AWS   false
  set_default SENPAI_SHOW_GCP   false
  set_default SENPAI_SHOW_AZURE false
  set_default SENPAI_SHOW_NAMESPACE true


  typeset -g blue
  typeset -g brown
  typeset -g cyan
  typeset -g green
  typeset -g magenta
  typeset -g red
  typeset -g white
  typeset -g yellow

  # Choose dark or bright color schema and use extended color palette if available
  if  [[ $SENPAI_THEME_DARK == true ]]; then
    if [[ -n ${terminfo[colors]} && ${terminfo[colors]} -ge 256 ]]; then
      blue='%F{33}'
      brown='%F{166}'
      cyan='%F{74}'
      green='%F{64}'
      darkgreen='%F{34}'
      red='%F{9}'
      darkred='%F{160}'
      white='%F{15}'
      yellow='%F{214}'
    else
      blue='%F{blue}'
      brown='%F{brown}'
      cyan='%F{cyan}'
      green='%F{green}'
      red='%F{red}'
      white='%F{white}'
      yellow='%F{yellow}'
    fi
  else
    if [[ -n ${terminfo[colors]} && ${terminfo[colors]} -ge 256 ]]; then
      blue='%F{21}'
      brown='%F{208}'
      cyan='%F{33}'
      green='%F{76}'
      darkgreen='%F{70}'
      red='%F{9}'
      darkred='%F{160}'
      white='%F{0}'
      yellow='%F{214}'
    else
      blue='%F{blue}'
      brown='%F{brown}'
      cyan='%F{cyan}'
      green='%F{green}'
      red='%F{red}'
      white='%F{black}'
      yellow='%F{yellow}'
    fi
  fi

  autoload -Uz add-zsh-hook
  autoload -Uz colors && colors

  prompt_opts=(cr percent sp subst)

  add-zsh-hook precmd prompt_senpai_precmd

  zstyle ':zim:git-info' verbose 'yes'
  zstyle ':zim:git-info:branch' format '%b'
  zstyle ':zim:git-info:commit' format '%c'
  zstyle ':zim:git-info:action' format "(${limegreen}%s%f)"
  zstyle ':zim:git-info:unindexed' format "${brown}●"
  zstyle ':zim:git-info:indexed' format "${green}●"
  zstyle ':zim:git-info:untracked' format "${red}●"
  zstyle ':zim:git-info:keys' format 'prompt' "${white}(%b%c%I%i%u${white})%f%s"

  # Init PROMPT
  PROMPT=""
  RPROMPT=""
  # Build prompt based on user settings
  # Do not print timestamp if it is disabled
	if [[ $SENPAI_SHOW_TIME == true ]]; then
		PROMPT+="\$(prompt_senpai_time)"
	fi

  # Do not print user if it is disabled
	if [[ $SENPAI_SHOW_USER == true ]]; then
		PROMPT+="${yellow}%n%f"
	fi

  # Do not print path if it is disabled
	if [[ $SENPAI_SHOW_USER == true ]] && [[ $SENPAI_SHOW_PATH == true ]]; then
		PROMPT+=" in ${green}%~%f"
	elif [[ $SENPAI_SHOW_PATH == true ]]; then
    PROMPT+="${green}%~%f% "
  fi

  # Do not print git status if it is disabled
#	if [[ $SENPAI_SHOW_GIT == true ]]; then
#		PROMPT+="\$(prompt_senpai_git)"
#	fi

  # Do not print git info if it is disabled
    if [[ $SENPAI_SHOW_GIT == true ]]; then
      PROMPT+="\$(prompt_senpai_git)"
    fi

  # Do not print virtual env if it is disabled
	if [[ $SENPAI_SHOW_VIRT == true ]]; then
		PROMPT+="\$(prompt_senpai_virtualenv)"
	fi

  # Do not print Kubernetes info if it is disabled
	if [[ $SENPAI_SHOW_K8S == true ]]; then
		PROMPT+="\$(k8s_info)
 ${yellow} —————» %f"
	fi

  if [[ $SENPAI_SHOW_NAMESPACE == true ]]; then
          PROMPT+="\$(k8_namespace)"
  fi


  # Do not print virtual env if it is disabled
	if [[ $SENPAI_SHOW_AWS == true ]]; then
		PROMPT+="\$(aws_info)"
	fi

  # Do not print virtual env if it is disabled
	if [[ $SENPAI_SHOW_GCP == true ]]; then
		PROMPT+="\$(gcp_info)"
	fi

  # Do not print virtual env if it is disabled
	if [[ $SENPAI_SHOW_AZURE == true ]]; then
		PROMPT+="\$(azure_info)"
	fi

  # Add the final prompt
  PROMPT+=" %(?.${white}.${darkred})❯%f "
}

prompt_senpai_setup "$@"
