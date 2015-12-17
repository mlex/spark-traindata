#!/bin/bash

S3_TRAINDATA_BUCKET=traindata.datalab

RAW_TRAINDATA_PATH=raw
GZ_TRAINDATA_PATH=raw_gz

S3_URL=s3://$S3_TRAINDATA_BUCKET

FILES=$(aws s3 ls $S3_URL/$RAW_TRAINDATA_PATH/ | awk '{print $4}')

echo -e "FILE LIST: \n$FILES\n\n"

for FILE in $FILES
do
  FILE_UNZIPPED=${FILE%.7z}
  FILE_GZIP=$FILE_UNZIPPED.gz

  echo "CLEANUP (remove $FILE, $FILE_UNZIPPED, $FILE_GZIP)..."
  rm -f ./$FILE
  rm -f ./$FILE_UNZIPPED
  rm -f ./$FILE_GZIP
  echo "CLEANED UP"

  echo "CHECK IF EXISTS $FILE_GZIP..."
  COUNT=$(aws s3 ls $S3_URL/$GZ_TRAINDATA_PATH/$FILE_GZIP | wc -l)
  if [ $COUNT != 0 ]
  then
    echo "SKIP FILE $FILE_GZIP (ALREADY EXISTS IN S3)"
    continue
  fi

  echo "DOWNLOAD $FILE..."
  aws s3 cp $S3_URL/$RAW_TRAINDATA_PATH/$FILE $FILE
  echo "7ZIP-FILE $FILE: $(file $FILE)"

  echo "UNZIP $FILE..."
  7z e $FILE
  echo "UNZIPPED-FILE $FILE_UNZIPPED: $(file $FILE_UNZIPPED)"

  echo "GZIP $FILE_UNZIPPED..."
  gzip $FILE_UNZIPPED
  echo "GZIP-FILE $FILE_GZIP: $(file $FILE_GZIP)"

  echo "UPLOADING $FILE_GZIP"
  aws s3 cp $FILE_GZIP $S3_URL/$GZ_TRAINDATA_PATH/$FILE_GZIP
  echo "FILE $FILE_GZIP: $(aws s3 ls $S3_URL/$GZ_TRAINDATA_PATH/$FILE_GZIP)"

  echo "CLEANUP (remove $FILE, $FILE_UNZIPPED, $FILE_GZIP)..."
  rm -f ./$FILE
  rm -f ./$FILE_UNZIPPED
  rm -f ./$FILE_GZIP
  echo "CLEANED UP"
done
