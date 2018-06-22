import os
import sys
rootdir = 'C:/Users/zjuni/fakeDir'

sys.stdout = open('C:/Users/zjuni/pythonOutput.txt', 'w')
for subdir, dirs, files in os.walk(rootdir):
    for file in files:
        fileName = os.path.join(subdir, file)
        #print fileName
        sasInvocation = "sas c:\myProgram.sas " + fileName
        print sasInvocation
        #os.system(sasInvocation)