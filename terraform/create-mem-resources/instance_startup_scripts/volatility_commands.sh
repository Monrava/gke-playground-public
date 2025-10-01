#!/bin/bash
output=$1
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.bash.Bash > $output/bash.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.check_idt.Check_idt > $output/checkidt.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.check_syscall.Check_syscall > $output/check_syscall.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.elfs.Elfs > $output/elfs.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.lsmod.Lsmod > $output/lsmod.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.lsof.Lsof > $output/lsof.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.mountinfo.MountInfo > $output/mountinfo.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.proc.Maps > $output/proc.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.psaux.PsAux > $output/psaux.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.pslist.PsList > $output/pslist.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.pstree.PsTree > $output/pstree.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.tty_check.tty_check > $output/tty_check.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q banners.Banners > $output/banners.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.check_afinfo.Check_afinfo > $output/Check_afinfo.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.check_creds.Check_creds > $output/Check_creds.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.check_modules.Check_modules > $output/Check_modules.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.envars.Envars > $output/Envars.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.envvars.Envvars > $output/Envvars.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.iomem.IOMem > $output/IOMem.txt
#python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.keyboard_notifiers.Keyboard_notifiers > $output/Keyboard_notifiers.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.kmsg.Kmsg > $output/Kmsg.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.psscan.PsScan > $output/PsScan.txt
python3 /root/volatility3/vol.py -s /root/volatility3/volatility3/symbols/dwarf2json_profile.json -f $output.lime -q linux.sockstat.Sockstat > $output/Sockstat.txt