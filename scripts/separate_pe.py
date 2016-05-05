#!usr/bin/python

from sys import argv

r1 = open(argv[2], "w")
r2 = open(argv[3], "w")

n = 0
print argv[1]
with open(argv[1], "r") as file_input:
    for line in file_input:
        if n < 8:
            n += 1
        else:
            n = 1
        if n <= 4:
            r1.write(line)
        else:
            r2.write(line)
