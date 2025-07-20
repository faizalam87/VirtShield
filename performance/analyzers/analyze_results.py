import sys
from pathlib import Path
import pandas as pd

def extract_iperf(log):
    for line in log.read_text().splitlines():
        if "sender" in line and "Mbits/sec" in line:
            parts = line.split()
            try:
                return float(parts[-2])
            except:
                return None
    return None

def extract_perf(log):
    cycles, instr, miss = None, None, None
    for line in log.read_text().splitlines():
        if "cycles" in line and cycles is None:
            cycles = int(line.strip().split()[0].replace(',', ''))
        elif "instructions" in line and instr is None:
            instr = int(line.strip().split()[0].replace(',', ''))
        elif "cache-misses" in line and miss is None:
            miss = int(line.strip().split()[0].replace(',', ''))
    return cycles, instr, miss

def main(log_dir, mode):
    log_dir = Path(log_dir)
    summary = {}

    iperf_val = extract_iperf(log_dir / "iperf.log")
    if iperf_val:
        summary["Throughput_Mbps"] = iperf_val

    cycles, instr, miss = extract_perf(log_dir / "perf_stat.log")
    if cycles:
        summary["CPU_Cycles"] = cycles
        summary["Instructions"] = instr
        summary["Cache_Misses"] = miss

    summary_file = log_dir / "summary.txt"
    with summary_file.open("w") as f:
        f.write(f"=== Summary ({mode}) ===\n")
        for k, v in summary.items():
            f.write(f"{k}: {v}\n")

    print(f"[✓] Results written to {summary_file}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
