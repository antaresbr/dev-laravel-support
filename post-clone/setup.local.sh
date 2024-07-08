#!/bin/bash

echo ""
echo "---[ $(dirname "$(realpath "${SCRIPT_DIR}")") ]---"
echo "---| post-clone/$(basename "${BASH_SOURCE[0]}")"

[ -z "${WORKSPACE_BASE_LIB_SH}" ] && echo -e "post-clone/setup-local | ERROR | WORKSPACE_BASE_LIB_SH not defined" && exit 1
[ -z "${POST_CLONE_SETUP_LIB_SH}" ] && wsError "post-clone/setup-local" "POST_CLONE_SETUP_LIB_SH not defined"
[ -z "${POST_CLONE_LIB_SH}" ] && wsError "post-clone/setup-local" "POST_CLONE_LIB_SH not defined"

#---[ setup-local ]---

#-- parameters

pclLoadSavedParams

[ -z "${PC_IGNORE_POST_CLONE_EXAMPLE}" ] || pCopyPostCloneExample=no
if [ -z "${pCopyPostCloneExample}" ]
then
  echo""
  envVarRead "Copy <post-clone> example to parent project?" "pCopyPostCloneExample" "default:yes|lower-case|hide-values" "y|yes|n|no"
fi

[ -z "${PC_IGNORE_GIT_REPO_EXAMPLE}" ] || pCopyGitRepoExample=no
if [ -z "${pCopyGitRepoExample}" ]
then
  echo""
  envVarRead "Copy <git-repo> example to parent project?" "pCopyGitRepoExample" "default:yes|lower-case|hide-values" "y|yes|n|no"
fi

[ -z "${PC_IGNORE_GITIGNORE_EXAMPLE}" ] || pCopyGitignoreExample=no
if [ -z "${pCopyGitignoreExample}" ]
then
  echo""
  envVarRead "Copy <.gitignore> example to parent project?" "pCopyGitignoreExample" "default:yes|lower-case|hide-values" "y|yes|n|no"
fi

echo ""
echo "---[ parameters ]---"
echo ""
echo "ENVIRONMENT : ${pEnvironment}"
echo ""
echo "pCopyPostCloneExample   : ${pCopyPostCloneExample}"
echo "pCopyGitRepoExample     : ${pCopyGitRepoExample}"
echo "pCopyGitignoreExample   : ${pCopyGitignoreExample}"
echo ""

[ -n "${pConfirm}" ] || envVarRead "Confirm parameters?" "pConfirm" "default:yes|lower-case|hide-values" "y|yes|n|no"
[ "${pConfirm:0:1}" == "y" ] || exit 0

if [ ! -f "${SCRIPT_DIR}/setup.local.env" ]
then
  echo""
  envVarRead "Save post-clone params?" "pSavePostcloneParams" "default:yes|lower-case|hide-values" "y|yes|n|no"
  if [ "${pSavePostcloneParams:0:1}" == "y" ]
  then
    echo "\
#!/bin/bash
pCopyPostCloneExample=\"${pCopyPostCloneExample}\"
pCopyGitRepoExample=\"${pCopyGitRepoExample}\"
pCopyGitignoreExample=\"${pCopyGitignoreExample}\"
" > "${SCRIPT_DIR}/setup.local.env"
  fi
fi

#-- actions

function doCopyPostCloneExample() {
  wsCertifyPath "$(realpath "${BASE_DIR}/../post-clone")"
  wsCopyFileIfNotExists "${BASE_DIR}/.example/support/post-clone/setup.local.sh.example" "${BASE_DIR}/../post-clone/setup.local.sh" "644"
  wsCopyFileIfNotExists "${BASE_DIR}/post-clone/.gitignore" "${BASE_DIR}/../post-clone/.gitignore" "644"
  wsCopyFileIfNotExists "${BASE_DIR}/post-clone/setup.sh" "${BASE_DIR}/../post-clone/setup.sh" "755"
}


function doCopyGitRepoExample() {
  wsCertifyPath "$(realpath "${BASE_DIR}/../.git-repo")"
  wsCopyFileIfNotExists "${BASE_DIR}/.example/support/git-repo/git-repo.env.sh.example" "${BASE_DIR}/../.git-repo/git-repo.env.sh" "644"
}


function doCopyGitignoreExample() {
  wsCopyFileIfNotExists "${BASE_DIR}/.example/support/.gitignore.example" "${BASE_DIR}/../.gitignore" "644"
}

#-- template and examples

echo ""
echo ": .bootstrap.sh"
wsCopyFileIfNotExists "${BASE_DIR}/.example/support/.bootstrap.sh" "${BASE_DIR}/../" "644"

echo ""
echo "---[ example to parent : post-clone ]---"
if [ -n "${PC_IGNORE_POST_CLONE_EXAMPLE}" ]
then
  echo "  ! ignored"
else
  [ "${pCopyPostCloneExample:0:1}" == "y" ] && doCopyPostCloneExample
  [ "${pCopyPostCloneExample:0:1}" == "y" ] || echo "  ! skiped"
fi

echo ""
echo "---[ example to parent : git-repo ]---"
if [ -n "${PC_IGNORE_GIT_REPO_EXAMPLE}" ]
then
  echo "  ! ignored"
else
  [ "${pCopyGitRepoExample:0:1}" == "y" ] && doCopyGitRepoExample
  [ "${pCopyGitRepoExample:0:1}" == "y" ] || echo "  ! skiped"
fi
