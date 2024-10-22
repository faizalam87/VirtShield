import csv
import docker
import time

# Connect to the Docker daemon
client = docker.from_env()

# Container Name
CONTAINER_NAME = "firewall"

# Output file
OUTPUT_FILE = "../Results/firewall_usage.csv"

# Sampling interval
INTERVAL = 0.5

def get_container_stats(container):
    """
    Get the CPU and Memory usage statistics of a Docker container.

    Parameters:
    container (docker.models.containers.Container): The Docker container object.

    Returns:
    tuple: A tuple containing CPU usage percentage, memory usage in bytes, and memory usage percentage.
    """
    # Get container stats
    stats = container.stats(stream=False)

    # Calculate CPU usage
    cpu_stats = stats['cpu_stats']
    precpu_stats = stats['precpu_stats']

    cpu_delta = cpu_stats['cpu_usage']['total_usage'] - precpu_stats['cpu_usage']['total_usage']
    system_delta = cpu_stats['system_cpu_usage'] - precpu_stats['system_cpu_usage']


    cpu_usage = (cpu_delta / system_delta) * 100.0

    # Get memory usage
    mem_usage = stats['memory_stats']['usage']
    mem_limit = stats['memory_stats']['limit']
    mem_percent = (mem_usage / mem_limit) * 100.0

    return cpu_usage, mem_usage, mem_percent


def monitor_container(container_name, interval, output_file):
    """
    Monitor CPU and Memory usage of specified Docker container at the given interval,
    and save results to a CSV file. Monitoring stops when either the container stops 
    or the user interrupts the monitoring process.

    Parameters saved are : Time, CPU Usage %, Memory Usage Bytes, Memory Usage %.
    """

    # Get container object
    container = client.containers.get(container_name)
    # Time stamp in seconds
    timestamp = 0

    with open(output_file, mode='w', newline='') as file:
        writer = csv.writer(file)
        writer.writerow(["Time", "CPU Usage %", "Memory Usage Bytes", "Memory Usage %"])

        try:
            while True:
                # Get container stats
                cpu_usage, mem_usage, mem_percent = get_container_stats(container)
                
                # Write to CSV file
                writer.writerow([timestamp, cpu_usage, mem_usage, mem_percent])

                # Increment timestamp
                timestamp += interval

                # Wait for the next interval
                time.sleep(interval)
        
        except KeyboardInterrupt:
            print("Monitoring stopped by user.")

monitor_container(CONTAINER_NAME, INTERVAL, OUTPUT_FILE)