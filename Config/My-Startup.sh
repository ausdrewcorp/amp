#!/bin/bash

# echo back all received arguments to the console
#echo "$@"

CONFIG_DIR="../Config"
KF2_DIR="KFGame/Config"
INI_FILE="${KF2_DIR}/LinuxServer-KFEngine.ini"

MAPS_FILE="${CONFIG_DIR}/My-Maps.csv"
MUTATORS_FILE="${CONFIG_DIR}/My-Mutators.csv"

## Steam Workshop Downloads

# Find [IpDrv.TcpNetDriver] in the INI_FILE file and paste the following under the heading
# Add the line DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload to that section. If there are other "DownloadManagers=" lines, make sure this # one is the first.
# Check if the line already exists
if ! grep -q "DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload" "$INI_FILE"; then
  # If it doesn't exist, add it after [IpDrv.TcpNetDriver]
  sed -i '/\[IpDrv.TcpNetDriver\]/a DownloadManagers=OnlineSubsystemSteamworks.SteamWorkshopDownload' "$INI_FILE"
fi

# Read CSV files and extract workshop IDs
WORKSHOP_IDS=()
for FILE in $MAPS_FILE $MUTATORS_FILE; do
  while IFS= read -r LINE || [ -n "$LINE" ]; do
    [[ $LINE = \#* ]] && continue
    [[ -z $LINE ]] && continue
    IFS=',' read -ra IDS <<< "$LINE"
    # Only add the ID part (before the comma)
    WORKSHOP_IDS+=("${IDS[0]}")
  done < "$FILE"
done

# Read .ini file
INI_LINES=()
while IFS= read -r LINE || [ -n "$LINE" ]; do
  INI_LINES+=("$LINE")
done < "$INI_FILE"

# Add header if not exists and get its index
HEADER_INDEX=-1
for i in "${!INI_LINES[@]}"; do
  if [[ ${INI_LINES[i]} = \[OnlineSubsystemSteamworks.KFWorkshopSteamworks\]* ]]; then
    HEADER_INDEX=$i
  elif [[ ${INI_LINES[i]} = \[IniVersion\]* ]] && [[ $HEADER_INDEX -eq -1 ]]; then
    HEADER_INDEX=$i
    INI_LINES=("${INI_LINES[@]:0:$i}" "[OnlineSubsystemSteamworks.KFWorkshopSteamworks]" "${INI_LINES[@]:$i}")
  fi
done

# Add new workshop items
for ID in "${WORKSHOP_IDS[@]}"; do
  if ! grep -q "ServerSubscribedWorkshopItems=$ID" "$INI_FILE"; then
    HEADER_INDEX=$((HEADER_INDEX+1))
    INI_LINES=("${INI_LINES[@]:0:$HEADER_INDEX}" "ServerSubscribedWorkshopItems=$ID" "${INI_LINES[@]:$HEADER_INDEX}")
  fi
done

# Remove non-existing workshop items
for i in "${!INI_LINES[@]}"; do
  if [[ ${INI_LINES[i]} = ServerSubscribedWorkshopItems=* ]]; then
    ID=${INI_LINES[i]#*=}
    if ! printf '%s\n' "${WORKSHOP_IDS[@]}" | grep -q -P "^$ID$"; then
      unset 'INI_LINES[i]'
    fi
  fi
done

# Ensure there is a single line gap between the last ServerSubscribedWorkshopItem and [IniVersion]
for ((i=${#INI_LINES[@]}-1; i>=0; i--)); do
  if [[ ${INI_LINES[i]} = \[IniVersion\]* ]]; then
    if [[ -n ${INI_LINES[i-1]} ]]; then
      INI_LINES=("${INI_LINES[@]:0:$i}" "" "${INI_LINES[@]:$i}")
    fi
    break
  fi
done

# Write back to .ini file
printf "%s\n" "${INI_LINES[@]}" > "$INI_FILE"


## Add Maps
# Read My-Maps.csv file
while IFS= read -r line
do
  # Ignore blank lines and lines starting with '#'
  if [[ -z "$line" ]] || [[ ${line:0:1} == '#' ]]; then
    continue
  fi

  # Split line by comma and get the second value (Map name)
  map_name=$(echo $line | cut -d ',' -f 2)

  # Check if the map datastore already exists in the KF2_DIR/LinuxServer-KFGame.ini file
  if ! grep -q "\[$map_name KFMapSummary\]" "$KF2_DIR/LinuxServer-KFGame.ini"; then
    # If it doesn't exist, append the new datastore to the file
    echo -e "\n[$map_name KFMapSummary]\nMapName=$map_name" >> "$KF2_DIR/LinuxServer-KFGame.ini"
  fi
done < "$CONFIG_DIR/My-Maps.csv"


## Add to map cycle 
# Read the LinuxServer-KFGame.ini file and extract the line that starts with GameMapCycles=
map_cycle_line=$(grep "^GameMapCycles=" "$KF2_DIR/LinuxServer-KFGame.ini")

# Remove the GameMapCycles= part and the parentheses to get the list of existing maps
existing_maps_str=${map_cycle_line#GameMapCycles=(Maps=(}
existing_maps_str=${existing_maps_str%))}

# Convert the list of existing maps into an array
IFS=',' read -r -a existing_maps <<< "$existing_maps_str"

# Read the My-Maps.csv file line by line
while IFS= read -r line
do
  # Ignore blank lines and lines starting with '#'
  if [[ -z "$line" ]] || [[ ${line:0:1} == '#' ]]; then
    continue
  fi

  # Split the line by comma and get the second value (Map name)
  map_name=$(echo $line | cut -d ',' -f 2)

  # Check if the map name already exists in the array of existing maps
  if ! printf '%s\n' "${existing_maps[@]}" | grep -q -P "^\"$map_name\"$"; then
    # If it doesn't exist, append it to the array
    existing_maps+=("\"$map_name\"")
  fi
done < "$CONFIG_DIR/My-Maps.csv"

# Convert the array back into a string, with each map enclosed in quotes and separated by commas
new_maps_str=$(IFS=','; echo "${existing_maps[*]}")

# Replace the GameMapCycles= line in the LinuxServer-KFGame.ini file with the new line
sed -i "s/^GameMapCycles=.*$/GameMapCycles=(Maps=($new_maps_str))/" "$KF2_DIR/LinuxServer-KFGame.ini"

# Extract port number from arguments
portNumber=$(echo $@ | grep -oP '(?<=Port=)\d+')

# If port number was found, use it to name the process
if [ -n "$portNumber" ]; then
    exec -a "KFServer-$portNumber" Binaries/Win64/KFGameSteamServer.bin.x86_64 "$@"
else
    exec -a "KFServer" Binaries/Win64/KFGameSteamServer.bin.x86_64 "$@"
fi