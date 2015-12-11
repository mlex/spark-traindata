#!/bin/bash

S3_TRAINDATA_BUCKET=traindata.datalab

RAW_TRAINDATA_PATH=raw
BZ_TRAINDATA_PATH=raw_bz2

S3_URL=s3://$S3_TRAINDATA_BUCKET

FILES=$(aws s3 ls $S3_URL/$RAW_TRAINDATA_PATH/ | awk '{print $4}')

echo -e "FILE LIST: \n$FILES\n\n"

for FILE in $FILES
do
  FILE_UNZIPPED=${FILE%.7z}
  FILE_BZIP=$FILE_UNZIPPED.bz2

  echo "CLEANUP (remove $FILE, $FILE_UNZIPPED, $FILE_BZIP)..."
  rm -f ./$FILE
  rm -f ./$FILE_UNZIPPED
  rm -f ./$FILE_BZIP
  echo "CLEANED UP"

  echo "DOWNLOAD $FILE..."
  aws s3 cp $S3_URL/$RAW_TRAINDATA_PATH/$FILE $FILE
  echo "7ZIP-FILE $FILE: $(file $FILE)"

  echo "UNZIP $FILE..."
  7z e $FILE
  echo "UNZIPPED-FILE $FILE_UNZIPPED: $(file $FILE_UNZIPPED)"

  echo "BZIP2 $FILE_UNZIPPED..."
  bzip2 $FILE_UNZIPPED
  echo "BZ2-FILE $FILE_BZIP: $(file $FILE_BZIP)"

  echo "UPLOADING $FILE_BZIP"
  aws s3 cp $FILE_BZIP $S3_URL/$BZ_TRAINDATA_PATH/$FILE_BZIP
  echo "FILE $FILE_BZIP: $(aws s3 ls $S3_URL/$BZ_TRAINDATA_PATH/$FILE_BZIP)"

  echo "CLEANUP (remove $FILE, $FILE_UNZIPPED, $FILE_BZIP)..."
  rm -f ./$FILE
  rm -f ./$FILE_UNZIPPED
  rm -f ./$FILE_BZIP
  echo "CLEANED UP"
done
