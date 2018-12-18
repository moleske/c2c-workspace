#!/usr/bin/env bash

function main() {
  function setup_aliases() {
    alias vim=nvim
    alias vi=nvim
    alias ll="ls -al"
    alias be="bundle exec"
    alias bake="bundle exec rake"
    alias drm='docker rm $(docker ps -a -q)'
    alias drmi='docker rmi $(docker images -q)'

    #git aliases
    alias gst="git status"
    alias gd="git diff"
    alias gap="git add -p"
    alias gup="git pull -r"
    alias gp="git push"
    alias ga="git add"

    # alias gbt="gobosh_target"
    # alias cft="cf_target"
    # alias cftl="cf_target local"
    # alias t="target"

    alias rg="ag"

    alias h?="history | grep"
    alias chg="credhub-get"
  }

  function setup_environment() {
    export CLICOLOR=1
    export LSCOLORS exfxcxdxbxegedabagacad

    # go environment
    export GOPATH=$HOME/go
    export GOBIN=$GOPATH/bin

    # git duet config
    export GIT_DUET_GLOBAL=true
    export GIT_DUET_ROTATE_AUTHOR=1

    # setup path
    export PATH=$GOBIN:$PATH

    export EDITOR=nvim
  }

  function setup_rbenv() {
    eval "$(rbenv init -)"
  }

  function setup_jenv() {
    eval "$(jenv init -)"
  }

  function setup_aws() {
    # set awscli auto-completion
    complete -C aws_completer aws
  }

  function setup_fasd() {
    local fasd_cache
    fasd_cache="$HOME/.fasd-init-bash"

    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
      fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fasd_cache"
    fi

    source "$fasd_cache"
    eval "$(fasd --init auto)"
  }

  function setup_completions() {
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  }

  function setup_direnv() {
    eval "$(direnv hook bash)"
  }

  function setup_gitprompt() {
    if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
      # git prompt config
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal
      export GIT_PROMPT_ONLY_IN_REPO=0
      export GIT_PROMPT_THEME="Custom"

      source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
    fi
  }

  function setup_colors() {
    local colorscheme
    colorscheme="${HOME}/.config/colorschemes/scripts/base16-monokai.sh"
    [[ -s "${colorscheme}" ]] && source "${colorscheme}"
  }


  function setup_ssh_agent() {
    if [[ ! -e ~/.ssh_agent ]]; then
      if [[ -n ${SSH_AUTH_SOCK} ]]; then
        ln -sf $SSH_AUTH_SOCK ~/.ssh_agent
      fi
    fi

    export SSH_AUTH_SOCK=~/.ssh_agent
  }

  local dependencies
    dependencies=(
        aliases
        environment
        colors
        rbenv
        aws
        fasd
        completions
        direnv
        gitprompt
        ssh_agent
      )

  for dependency in ${dependencies[@]}; do
    eval "setup_${dependency}"
    unset -f "setup_${dependency}"
  done
}

function reload() {
  source "${HOME}/.bash_profile"
}

function cf_bosh_lite {
    if (( $# == 0 ))
			then echo usage: cf_bosh_lite password;
    else
    	cf api api.bosh-lite.com --skip-ssl-validation && cf auth admin $1 && cf t -o o -s s
    fi
}

function cf_create_org {
		cf create-org o && cf t -o o && cf create-space s && cf t -o o -s s
}

# function bosh_ssh_c2c {
#   if (( $# != 1 ))
#     then echo "Usage: bosh_ssh_c2c <env>"
#   else
#     bosh target bosh.$1.c2c.cf-app.com
#     bosh download manifest $1-diego /tmp/$1-diego.yml
#     bosh -d /tmp/$1-diego.yml ssh --gateway_host bosh.$1.c2c.cf-app.com --gateway_user vcap --gateway_identity_file ~/workspace/cf-networking-deployments/environments/$1/keypair/id_rsa_bosh
#   fi
# }

cf_target () {
  if [ $# = 0 ]; then
    echo "missing environment-name"
    echo ""
    echo "example usage:"
    echo "cft environment-name"
    return
  fi
  env=$1
  workspace=$2

  if [ "$env" = "ci" ]; then
    echo "no CF deployed in ci env."
    return
  fi
  
  # if [ "$env" = "local" ] || [ "$env" = "lite" ]; then
  #   password=$(grep cf_admin_password "${HOME}/workspace/cf-networking-deployments/environments/${env}/deployment-vars.yml" | cut -d" " -f2)
  # else
    password=$(credhub get -n "/bosh-${env}/cf/cf_admin_password" | bosh int --path /value -)
  # fi

  if [ "$workspace" = "routing" ]; then
    system_domain="${env}.routing.cf-app.com"
  elif [ "$env" = "local" ] || [ "$env" = "lite" ]; then
    system_domain="bosh-lite.com"
  else
    system_domain="${env}.c2c.cf-app.com"
  fi

  cf api "api.${system_domain}" --skip-ssl-validation
  cf auth admin "${password}"
}

# what makes sense for geode/gemfire?
# gobosh_target ()
# {
#   gobosh_untarget
#   if [ $# = 0 ]; then
#     return
#   fi
#   export BOSH_ENV=$1
#   if [ "$BOSH_ENV" = "local" ] || [ "$BOSH_ENV" = "lite" ]; then
#     gobosh_target_lite
#     return
#   fi

#   if [[ "${BOSH_ENV}" == "ci" ]]; then
#     pushd $(mktemp -d) > /dev/null
#       gsutil cp gs://c2c-bbl-states/ci ci.tgz
#       tar xf ci.tgz
#       eval "$(bbl print-env)"
#     popd > /dev/null
#     export BOSH_DEPLOYMENT="concourse"
#     return
#   fi

#   workspace=$2
#   if [ "$workspace" = "pcf" ]; then
#     export BOSH_DIR=~/workspace/pcf-networking-deployments/environments/$BOSH_ENV
#   elif [ "$workspace" = "routing" ]; then
#     export BOSH_DIR=~/workspace/deployments-routing/$BOSH_ENV/bbl-state
#   else
#     export BOSH_DIR=~/workspace/cf-networking-deployments/environments/$BOSH_ENV
#   fi

#   pushd $BOSH_DIR 1>/dev/null
#       eval "$(bbl print-env)"
#   popd 1>/dev/null

#   export BOSH_DEPLOYMENT="cf"
# }

# gobosh_untarget ()
# {
#   unset BOSH_ENV
#   unset BOSH_DIR
#   unset BOSH_USER
#   unset BOSH_PASSWORD
#   unset BOSH_ENVIRONMENT
#   unset BOSH_GW_HOST
#   unset BOSH_GW_PRIVATE_KEY
#   unset BOSH_CA_CERT
#   unset BOSH_DEPLOYMENT
#   unset BOSH_CLIENT
#   unset BOSH_CLIENT_SECRET
# }

# target ()
# {
#   gobosh_target ${@}
#   cf_target ${@}
# }

# readd_local_route ()
# {
#   ips="10.244.0.0/16"
#   gw="192.168.50.6"
#   sudo route delete -net "$ips" "$gw"
#   sudo route add -net "$ips" "$gw"
# }
# ssh_bosh_lite_director ()
# {
#   local creds=~/workspace/cf-networking-deployments/environments/local/creds.yml
#   bosh int $creds --path /jumpbox_ssh/private_key > /tmp/jumpbox.key
#   chmod 600 /tmp/jumpbox.key
#   ssh jumpbox@192.168.50.6 -i /tmp/jumpbox.key
# }

# gobosh_build_manifest ()
# {
#   bosh -d cf build-manifest -l=$BOSH_DIR/deployment-env-vars.yml --var-errs ~/workspace/cf-deployment/cf-deployment.yml
# }

# gobosh_patch_manifest ()
# {
#   pushd ~/workspace/cf-deployment 1>/dev/null
#     git apply ../cf-networking-ci/netman-cf-deployment.patch
#   popd 1>/dev/null
# }

extract_manifest ()
{
  bosh task $1 --debug | deployment-extractor
}

create_upload ()
{
  bosh create-release --force --timestamp-version && bosh upload-release
}

# upload_bosh_stemcell () {
#   STEMCELL_VERSION="$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path=/stemcells/0/version)"
#   echo "will upload stemcell ${STEMCELL_VERSION}"
#   bosh -e vbox upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION}"
# }

# gobosh_deploy ()
# {
#   bosh deploy -n ~/workspace/cf-deployment/cf-deployment.yml \
#   -o ~/workspace/cf-deployment/operations/use-compiled-releases.yml \
#   -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
#   -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/use-latest.yml \
#   -o $BOSH_DIR/opsfile.yml \
#   --vars-store $BOSH_DIR/vars-store.yml \
#   -v system_domain=$(echo "${BOSH_DIR}" | cut -f 7 -d '/').c2c.cf-app.com
# }

# unbork_consul ()
# {
#   bosh vms | grep consul | cut -d ' ' -f1 > /tmp/consul-vms
#   cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit stop consul_agent"
#   cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo rm -rf /var/vcap/store/consul_agent/*"
#   cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit start consul_agent"
# }

# function windows_port_forward() {
#   echo "Port forwarding from $1"
#   ssh -f -L 3389:$1:3389 -N -i ${BOSH_GW_PRIVATE_KEY} ${BOSH_GW_USER}@${BOSH_GW_HOST}
# }

default_hours() {
  local current_hour=$(date +%H | sed 's/^0//')
  local result=$((17 - current_hour))
  if [[ ${result} -lt 1 ]]; then
    result=1
  fi
  echo -n ${result}
}

set_key() {
  local hours=$1

  /usr/bin/ssh-add -D

  echo "Setting hours to: $hours"
  lpass show --notes 'ProductivityTools/id_rsa' | /usr/bin/ssh-add -t ${hours}H -
}

set-git-keys() {
  local email=$1
  local hours=$2

  if [[ -z ${email} ]]; then
    echo "Usage: $0 [LastPass email or git author initials] [HOURS (optional)]"
    return
  fi

  if git_author_path "/authors/$email" >/dev/null 2>&1; then
    echo "Adding key for $(bosh int ${HOME}/.git-authors --path="/authors/$email" | sed 's/;.*//')"
    email="$(bosh int ${HOME}/.git-authors --path="/authors/$email" | sed 's/;.*//')@$(bosh int ${HOME}/.git-authors --path="/email/domain")"
  fi

  if [[ -z ${hours} ]]; then
    hours=$(default_hours)
  fi

  if ! [[ $(lpass status) =~ $email ]]; then
    lpass login "$email"
  fi
  set_key ${hours}
}

main
unset -f main
export PATH="/usr/local/opt/mysql@5.7/bin:$PATH"
