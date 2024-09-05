#!/bin/sh
#echo launching engine;
if ./PcdrEngine; then 
#echo engine exited normally, cleaning up...;
	sh cleanup-shm.sh;
#	echo cleanup complete.;
else 
#echo engine exited abnormally, cleaning up...;
	sh cleanup-shm.sh;
#echo cleanup complete.;
fi

#echo removing temporary files...;
rm -f cleanup-shm.sh;

