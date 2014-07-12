#!/bin/bash
# createUser.sh userName passWord \template\root\path
USERNAME="$1";
MyPassword="$2";
MyTemplatePath="$3";
# -------------------------------------
is_user()
{
  egrep -i "^$1" /etc/passwd > /dev/null 2>&1;
  return "$?";
}
# -------------------------------------
is_group()
{
  egrep -i "^$1" /etc/group > /dev/null 2>&1;
  return "$?";
}
# -------------------------------------
if ! is_user "$USERNAME" ; then
    echo " This script will create a user and ask for password using useradd and passwd command";
    if ! is_group "$USERNAME" ; then
        groupadd "$USERNAME";
    fi
    useradd -m -g "$USERNAME" -G "${USERNAME}",users -s /bin/bash "$USERNAME";
    
#    groupadd wittywizard;
#    useradd -m -g wittywizard -G wittywizard,users -s /bin/bash wittywizard;
#    echo -e "The1Wizard2Witty4Flesh\nThe1Wizard2Witty4Flesh\n" | passwd wittywizard;
#    mkdir -p /home/wittywizard/run;
#    mkdir -p /home/wittywizard/build;
#    chown -R wittywizard:wittywizard /home/wittywizard;

#    groupadd lightwizzard;
#    useradd -m -g lightwizzard -G lightwizzard,users -s /bin/bash lightwizzard;
#    echo -e "Trinary1Bit!Lan4Me2\nTrinary1Bit!Lan4Me2\n" | passwd lightwizzard;
#    mkdir -p /home/lightwizzard/run;
#    chown -R lightwizzard:lightwizzard /home/lightwizzard;

#    groupadd vetshelpcenter;
#    useradd -m -g vetshelpcenter -G vetshelpcenter,users -s /bin/bash vetshelpcenter;
#    echo -e "Trinary1Bit2Lan34Me\nTrinary1Bit2Lan34Me\n" | passwd vetshelpcenter;
#    mkdir -p /home/vetshelpcenter/run;
#    mkdir -p /home/vetshelpcenter/build;
#    chown -R vetshelpcenter:vetshelpcenter /home/vetshelpcenter;

#    groupadd modtekcomputers;
#    useradd -m -g modtekcomputers -G modtekcomputers,users -s /bin/bash modtekcomputers;
#    echo -e "Jason1!2@3#4$\nJason1!2@3#4$\n" | passwd modtekcomputers;
#    mkdir -p /home/modtekcomputers/run;
#    mkdir -p /home/modtekcomputers/build;
#    chown -R modtekcomputers:modtekcomputers /home/modtekcomputers;

#    groupadd thelastoutpost;
#    useradd -m -g thelastoutpost -G thelastoutpost,users -s /bin/bash thelastoutpost;
#    echo -e "Binary1Bit!Lan2\nBinary1Bit!Lan2\n" | passwd thelastoutpost;
#    mkdir -p /home/thelastoutpost/run;
#    mkdir -p /home/thelastoutpost/build;
#    chown -R thelastoutpost:thelastoutpost /home/thelastoutpost;

#    groupadd thedarkwizzard;
#    useradd -m -g thedarkwizzard -G thedarkwizzard,users -s /bin/bash thedarkwizzard;
#    echo -e "Trinary1Bit!Lan4Me2\nTrinary1Bit!Lan4Me2\n" | passwd thedarkwizzard;
#    mkdir -p /home/thedarkwizzard/run;
#    chown -R thedarkwizzard:thedarkwizzard /home/thedarkwizzard;

#    groupadd greywizzard;
#    useradd -m -g greywizzard -G greywizzard,users -s /bin/bash greywizzard;
#    echo -e "Trinary1Bit!Lan4Me2\nTrinary1Bit!Lan4Me2\n" | passwd greywizzard;
#    mkdir -p /home/greywizzard/run;
#    chown -R greywizzard:greywizzard /home/greywizzard;


    
    echo -e "${MyPassword}\n${MyPassword}\n" | passwd "$USERNAME";
    echo "Now make folders we need and set permissions";
    mkdir -p /home/"$USERNAME"/run;
    chown -R "$USERNAME:$USERNAME" /home/"$USERNAME";
fi
# -------------------------------------

