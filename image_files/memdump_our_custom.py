#!/usr/bin/env python3

# based on https://davidebove.com/blog/?p=1620

import sys
import os
import re
import psutil
import argparse

def get_pid(process_name: str):
    # https://stackoverflow.com/questions/2703640/process-list-on-linux-via-python
    pids = []
    for proc in psutil.process_iter():
        if process_name in proc.name():
            pids.append(proc.pid)
    return pids

if __name__ == "__main__":
    # Prepare parser
    parser = argparse.ArgumentParser(description="Process name to map PID for.")
    # Define argument
    parser.add_argument("--process_name", type=str, required=True)
    process_name = parser.parse_args().process_name

    print(f"Process name was: ")
    print(process_name)
    
    pids = get_pid(process_name)
    print("pids was")
    print(pids)
    
    if pids != []:
        for pid in pids:
            map_path = f"/proc/{pid}/maps"
            mem_path = f"/proc/{pid}/mem"

            with open(map_path, 'r') as map_f, open(mem_path, 'rb', 0) as mem_f:
                for line in map_f.readlines():  # for each mapped region
                    m = re.match(r'([0-9A-Fa-f]+)-([0-9A-Fa-f]+) ([-r])', line)
                    if m.group(3) == 'r':  # readable region
                        start = int(m.group(1), 16)
                        end = int(m.group(2), 16)
                        # hotfix: OverflowError: Python int too large to convert to C long
                        # 18446744073699065856
                        if start > sys.maxsize:
                            continue
                        mem_f.seek(start)  # seek to region start
                        region_start = hex(mem_f.seek(start))
                        region_end = hex(mem_f.seek(end))
                        
                        try:
                            chunk = mem_f.read(end - start)  # read region contents
                            #sys.stdout.buffer.write(chunk)
                            import sys
                            try:
                                with open(f'pid_process_capture_for_{process_name}_with_pid_{pid}_region_start_{region_start}_region_end_{region_end}_', 'a') as sys.stdout:
                                    print(sys.stdout.buffer.write(chunk))
                            except OSError:
                                print(f"Could not open/write file: pid_process_capture_for_pid_{pid}")
                                sys.exit()
                        except OSError:
                            continue
