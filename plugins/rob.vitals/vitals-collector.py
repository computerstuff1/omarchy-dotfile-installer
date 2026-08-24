#!/usr/bin/env python3
"""System vitals collector for the Omarchy rob.vitals bar widget.

Streams one JSON object per line on stdout every --interval seconds:
  {"cpu": 12.3, "mem": 45.2, "disk": 61.0}

Reads /proc directly; no third-party modules, no root. CPU is measured as a
delta between ticks (the first sample is not representative, so it is emitted
as null until the second tick).
"""

import json
import os
import shutil
import sys
import time


def read(path, default=None):
    try:
        with open(path) as f:
            return f.read()
    except OSError:
        return default


def read_int(path):
    val = read(path)
    return int(val) if val is not None else None


def cpu_total():
    stat = read("/proc/stat")
    if not stat:
        return None
    line = stat.splitlines()[0]
    fields = line.split()[1:]
    if len(fields) < 4:
        return None
    user = int(fields[0])
    nice = int(fields[1])
    system = int(fields[2])
    idle = int(fields[3])
    iowait = int(fields[4]) if len(fields) > 4 else 0
    irq = int(fields[5]) if len(fields) > 5 else 0
    softirq = int(fields[6]) if len(fields) > 6 else 0
    steal = int(fields[7]) if len(fields) > 7 else 0
    busy = user + nice + system + irq + softirq + steal
    total = busy + idle + iowait
    return busy, total


def mem_percent():
    meminfo = read("/proc/meminfo")
    if not meminfo:
        return None
    total = available = None
    for line in meminfo.splitlines():
        if line.startswith("MemTotal:"):
            total = int(line.split()[1])
        elif line.startswith("MemAvailable:"):
            available = int(line.split()[1])
    if not total:
        return None
    used = total - (available if available is not None else total)
    return used * 100.0 / total


def disk_percent(path="/"):
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return None
    return usage.used * 100.0 / usage.total


def main():
    interval = 1.0
    args = sys.argv[1:]
    while args:
        if args[0] == "--interval":
            if len(args) > 1:
                interval = max(0.2, float(args[1]))
                args = args[2:]
                continue
        args = args[1:]

    prev = None
    while True:
        cur = cpu_total()
        cpu = None
        if prev and cur and prev[1] > 0:
            d_busy = cur[0] - prev[0]
            d_total = cur[1] - prev[1]
            if d_total > 0:
                cpu = round(d_busy * 100.0 / d_total, 1)
        prev = cur
        mem = mem_percent()
        disk = disk_percent()
        snapshot = {"cpu": cpu, "mem": round(mem, 1) if mem is not None else None,
                    "disk": round(disk, 1) if disk is not None else None}
        sys.stdout.write(json.dumps(snapshot) + "\n")
        sys.stdout.flush()
        time.sleep(interval)


if __name__ == "__main__":
    main()