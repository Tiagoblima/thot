# *- python -*

# thot package for statistical machine translation
# Copyright (C) 2017 Adam Harasimowicz
 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.
 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
 
# You should have received a copy of the GNU Lesser General Public License
# along with this program; If not, see <http://www.gnu.org/licenses/>.

"""
Converts log file generated by Thot server to serialize output
from concurrent threads and make it more readable.
"""

import argparse
import re

from collections import defaultdict, deque


def extract_thread_id(line):
    """
    Look for thread ID in passed log line. If there is not the ID
    then it returns None.
    """
    match = re.match('(0x[0-9a-f]+)\t', line)

    if match:
        return match.group(1)
    else:
        return None


def is_first_request_line(line):
    match = re.search('0x[0-9a-f]+\t-{52}', line)

    return match is not None


def is_last_request_line(line):
    match = re.search('0x[0-9a-f]+\tElapsed time: [0-9]+\.[0-9]+ secs', line)

    return match is not None


def check_if_buffers_empty(unfinished_output_buf, finished_output_buf,
                           request_order):
    """
    Check if all buffered requests have been printed. If not then the most
    likely there is an error in code as the program should only reorder
    an original output so all information should be present.
    """
    empty = True

    if len(unfinished_output_buf):
        print 'ERROR: Some uncompleted information about requests left'
        empty = False
        for _, l in unfinished_output_buf.items():
            print l
    if len(finished_output_buf):
        print 'ERROR: Some completed requests have not been printed'
        empty = False
        for _, l in finished_output_buf.items():
            print l
    if len(request_order):
        print 'ERROR: Request queue is not empty'
        empty = False
        for r in request_order:
            print r

    return empty


def group_thread_output(logFileName):
    # Buffer request logs until they are not complete
    # For each TID we store list of printed lines in the log
    unfinished_output_buf = defaultdict(list)
    # Records the order of request arriving
    request_order = deque()
    # Buffer for complete request logs
    # For each TID we store list of completed request outputs
    # Single request output contains many lines
    finished_output_buf = defaultdict(deque)

    with open(logFileName, 'r') as f:
        for line in f:
            tid = extract_thread_id(line)
            if tid is None:
                print line,
            else:
                unfinished_output_buf[tid].append(line)

                # Add request TID to the queue to remember order of arriving
                if is_first_request_line(line):
                    request_order.append(tid)

                # Move request to buffer with complete logs if it is finished
                if is_last_request_line(line):
                    request_log = ''.join(unfinished_output_buf[tid])
                    finished_output_buf[tid].append(request_log)
                    del unfinished_output_buf[tid]

                # Check if the request from the queue head is ready to print
                while len(request_order) > 0:
                    head_tid = request_order[0]
                    if head_tid in finished_output_buf:
                        # Request is ready to print
                        request_order.popleft()
                        request_log = finished_output_buf[head_tid].popleft()
                        print request_log,
                        # Remove key if all elements printed for TID
                        if len(finished_output_buf[head_tid]) == 0:
                            del finished_output_buf[head_tid]
                    else:
                        break  # The first request in the queue is not ready to print yet

    return check_if_buffers_empty(unfinished_output_buf, finished_output_buf,
                                  request_order)


if __name__ == '__main__':
    # Parse input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('logfile', help='Path to log file to convert')
    args = parser.parse_args()

    if not group_thread_output(args.logfile):
        exit(1)  # Error