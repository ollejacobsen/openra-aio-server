#!/bin/sh

export APP_DIR="${HOME}/app"

# Specific envs for this script
Version="${RELEASE_VERSION:-"latest"}" # playtest-20260222|release-20250330-v4|1.08.2|1.08-PreRelease-1
Game="${GAME:-"RedAlert"}" # RedAlert|Dune2000|TiberianDawn|TiberianDawnHD|CombinedArms|HardVacuum
SupportedGames="RedAlert TiberianDawn Dune2000 TiberianDawnHD CombinedArms HardVacuum"

# These envs are set by the Dockerfile, but can be overridden at runtime if needed
DownloadArchive="${DOWNLOAD_DIR}"
SupportDir="${DATA_DIR}"
AppDir="${APP_DIR}"

# Function to generate the correct download URL based on Version and Game
# Example URL:s
#https://github.com/OpenRA/TiberianDawnHD/releases/download/playtest-20260222/TiberianDawnHD-playtest-20260222-x86_64.AppImage
#https://github.com/OpenRA/TiberianDawnHD/releases/download/release-20250330-v4/TiberianDawnHD-release-20250330-x86_64.AppImage
#https://github.com/Inq8/CAmod/releases/download/1.08.2/CombinedArms-1.08.2-x86_64.AppImage
#https://github.com/Inq8/CAmod/releases/download/1.08-PreRelease-1/CombinedArms-1.08-PreRelease-1-x86_64.AppImage
#https://github.com/OpenRA/OpenRA/releases/download/playtest-20260222/OpenRA-Red-Alert-playtest-x86_64.AppImage
#https://github.com/OpenRA/OpenRA/releases/download/playtest-20260222/OpenRA-Tiberian-Dawn-playtest-x86_64.AppImage
#https://github.com/OpenRA/OpenRA/releases/download/playtest-20260222/OpenRA-Dune-2000-playtest-x86_64.AppImage
#https://github.com/OpenRA/OpenRA/releases/download/release-20250330/OpenRA-Dune-2000-x86_64.AppImage
#https://github.com/OpenRA/OpenRA/releases/download/release-20250330/OpenRA-Red-Alert-x86_64.AppImage
#https://github.com/OpenHV/OpenHV/releases/download/20250725/OpenHV-20250725-x86_64.AppImage
make_download_url() {
  local version="$1"
  local game="$2"

  # HardVacuum (HVmod)
  if [ "$game" = "HardVacuum" ]; then
    echo "https://github.com/OpenHV/OpenHV/releases/download/$version/OpenHV-$version-x86_64.AppImage"
    return
  fi

  # CombinedArms (CAmod)
  if [ "$game" = "CombinedArms" ]; then
    if echo "$version" | grep -q "PreRelease"; then
      echo "https://github.com/Inq8/CAmod/releases/download/$version/CombinedArms-$version-x86_64.AppImage"
    else
      echo "https://github.com/Inq8/CAmod/releases/download/$version/CombinedArms-$version-x86_64.AppImage"
    fi
    return
  fi

  # TiberianDawnHD
  if [ "$game" = "TiberianDawnHD" ]; then
    if echo "$version" | grep -q "playtest"; then
      echo "https://github.com/OpenRA/TiberianDawnHD/releases/download/$version/TiberianDawnHD-$version-x86_64.AppImage"
    elif echo "$version" | grep -q "release"; then
      echo "https://github.com/OpenRA/TiberianDawnHD/releases/download/$version/TiberianDawnHD-$version-x86_64.AppImage"
    fi
    return
  fi

  # OpenRA main repo (RedAlert, TiberianDawn, Dune2000)
  if [ "$game" = "RedAlert" ] || [ "$game" = "TiberianDawn" ] || [ "$game" = "Dune2000" ]; then
    # Determine repo and artifact name
    local repo="OpenRA"
    local artifact=""
    local tag=""
    if echo "$version" | grep -q "playtest"; then
      tag="playtest"
      case "$game" in
        "RedAlert") artifact="OpenRA-Red-Alert-playtest-x86_64.AppImage" ;;
        "TiberianDawn") artifact="OpenRA-Tiberian-Dawn-playtest-x86_64.AppImage" ;;
        "Dune2000") artifact="OpenRA-Dune-2000-playtest-x86_64.AppImage" ;;
      esac
      echo "https://github.com/OpenRA/OpenRA/releases/download/$version/$artifact"
    elif echo "$version" | grep -q "release"; then
      case "$game" in
        "RedAlert") artifact="OpenRA-Red-Alert-x86_64.AppImage" ;;
        "TiberianDawn") artifact="OpenRA-Tiberian-Dawn-x86_64.AppImage" ;;
        "Dune2000") artifact="OpenRA-Dune-2000-x86_64.AppImage" ;;
      esac
      echo "https://github.com/OpenRA/OpenRA/releases/download/$version/$artifact"
    fi
    return
  fi

  # Fallback
  echo "Unknown game/version combination: $game $version" >&2
  return 1
}

# Function to extract AppImage
extract_appimage() {
  _appimage_file="$1"
  echo "Extract the AppImage ${_appimage_file} to ${AppDir}"
  cd "$AppDir" || exit
  chmod +x "${_appimage_file}" || { echo "Failed to make ${_appimage_file} executable"; exit 1; }
  "${_appimage_file}" --appimage-extract # 2>/dev/null # Suppress output to avoid cluttering logs
  mv squashfs-root/* ./
  rm -rf squashfs-root
}

# Function to validate the game name against the supported games list
validate_game() {
  for supported in $SupportedGames; do
    if [ "$Game" = "$supported" ]; then
      return 0
    fi
  done
  echo "Unknown game: $Game"
  echo "Valid options are: $SupportedGames"
  exit 1
}

# Function to set MOD environment variable based on the game
set_mod_env() {
  case "$Game" in
    "RedAlert") export Mod="ra" ;;
    "TiberianDawn") export Mod="cnc" ;;
    "Dune2000") export Mod="d2k" ;;
    "TiberianDawnHD") export Mod="cnc" ;;
    "CombinedArms") export Mod="ca" ;;
    "HardVacuum") export Mod="hv" ;;
    *) echo "Unknown game: $Game" >&2; exit 1 ;;
  esac
}

check_directory_permissions() {
  for dir_var in "DownloadArchive" "SupportDir" "AppDir"; do
    eval dir="\${$dir_var}"
    testfile="${dir}/.writetest"
    if ! touch "$testfile" 2>/dev/null; then
      echo "${dir_var} directory ${dir} is not writable. Check permissions."
      echo "The folder is probably mapped from the host. This is two suggestions to fix this issue:"
      echo " 1. On host run: \`sudo chown -R 99:100 <directory>\` to set the owner to the default UID and GID used in the container (99:100)."
      echo " 2. On host run: \`sudo chmod -R 777 <directory>\` to make the directory writable by all users."
      exit 1
    fi
    rm -f "$testfile"
  done
}

if [ "$Version" = "latest" ]; then
  case "$Game" in
    "TiberianDawnHD") latestVersionUrl=https://api.github.com/repos/OpenRA/TiberianDawnHD/releases/latest ;;
    "CombinedArms") latestVersionUrl=https://api.github.com/repos/inq8/camod/releases/latest ;;
    "HardVacuum") latestVersionUrl=https://api.github.com/repos/OpenHV/OpenHV/releases/latest ;;
    *) latestVersionUrl=https://api.github.com/repos/OpenRA/OpenRA/releases/latest ;;
  esac
  Version=$(curl -s $latestVersionUrl | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  echo "$Version"
fi

# Verifies that the game name is valid.
validate_game

check_directory_permissions

# Stats
echo "=================================================================="
echo "Game: ${Game}"
echo "Version: ${Version}"
echo "------------------------------------------------------------------"

tag=${Game}-${Version}
DownloadFile=${DownloadArchive}/${tag}_x86_64.AppImage

# Check if file exists on disk, if not download it
if [ ! -f "${DownloadFile}" ]; then
  url=$(make_download_url "$Version" "$Game")
  echo "File ${DownloadFile} does not exist, starting download from ${url}"

  # Download the file using curl and check for errors
  curl -fSL "${url}" --create-dirs --output "${DownloadFile}"
  if [ $? -ne 0 ]; then
    echo "Download failed! Check the URL or your network connection."
    rm -f "${DownloadFile}" # Remove the file if it was partially downloaded
    exit 1
  fi
else
  echo "File ${DownloadFile} already exists, skipping download"
fi

# Check if app directory exists, if not create it
if [ ! -d "$AppDir" ]; then
  mkdir "$AppDir"
fi

extract_appimage "${DownloadFile}"

# Set the MOD environment variable based on the game.
set_mod_env

# Replace the default AppRun with our custom ServerRun script
echo "Replacing default AppRun from AppImage with custom ServerRun"
cp ${HOME}/ServerRun "${AppDir}/AppRun"
echo "=================================================================="

# Ready to run the game
echo "\nStarting ${Game} ${Version} \n"
export GAME=${Game}
${AppDir}/AppRun