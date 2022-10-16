#!/usr/bin/python
import sys

csvpath=sys.argv[1]
vagrantfolder=sys.argv[2]
provscript=sys.argv[3]
hostvarspath=sys.argv[4]
vagranttemplate=sys.argv[5]
image=sys.argv[6]
inventorypath=sys.argv[7]

csv = open(csvpath,"r")
vagrant = open(vagranttemplate,"r").read()
headers = []
groups = {}

with open(vagrantfolder+"/Vagrantfile","w") as vgrf:
        for line in csv:
                if "%" in line:
                        headers = line.replace("#%","").split(";")

                if ("#" not in line) and (";" in line):
                        towrite = vagrant
                        linesplited = line.split(";")
                        towrite = towrite.replace('%IMG',image)
                        towrite = towrite.replace('%VM',linesplited[0])
                        towrite = towrite.replace('%MAC',linesplited[1].replace(':',''))
                        towrite = towrite.replace('%CPU',linesplited[3])
                        towrite = towrite.replace('%MEM',linesplited[4])
                        towrite = towrite.replace('%DISK',linesplited[5])
                        towrite = towrite.replace('%SCRIPT',provscript)
                        towrite = towrite.replace('%DOMAINPATH',vagrantfolder)
                        vgrf.write(towrite)

                        with open(hostvarspath+"/"+linesplited[0]+".yml","w") as hostvar:
                                for i in range(len(headers)):
                                        hostvar.write(headers[i].strip()+": "+linesplited[i]+"\n")

                        clasif = linesplited[-1].replace('\n','').split('-')
                        for i in range(0,len(clasif)):
                                if clasif[i] not in groups.keys():
                                        groups[clasif[i]] = []
                                if (i>0) and (clasif[i] not in groups[clasif[i-1]]):
                                        groups[clasif[i-1]].append(clasif[i])

with open(inventorypath,"w") as invw:
        for key in groups.keys():
                lst = groups[key]
                if len(lst)>0:
                        invw.write("["+key+"]\r\n")
                        for item in lst:
                                if len(groups[item])==0:
                                        invw.write(item+"\r\n")
                        invw.write("\r\n")
                        invw.write("["+key+":children]\r\n")
                        for item in lst:
                                if len(groups[item])>0:
                                        invw.write(item+"\r\n")
                        invw.write("\r\n")
