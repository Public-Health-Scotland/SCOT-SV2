for file in /data/encrypted2/inbox/*summary_qc_GGC/*.csv
do

	# clean up IDs and set up files
	keyfile="/data/encrypted2/keyfile.txt"
	foldername=`echo $file | rev | cut -d '/' -f1 | rev | sed "s/_summary_qc_GGC.csv//g"`
	runname=`ls -ld /data/encrypted2/outputs/*$foldername | grep "$foldername" | cut -d'_' -f2`
	workingdir="/data/encrypted2/workingdir/scratch/CLIMB_prep"
	mkdir $workingdir
	cd $workingdir
	cat $file | grep "Y.$" | awk -F ',' '{print $1}' | sed "s/^V/V,/g" | sed "s/_/\./g" | sed "s/\.S[[:digit:]]/_/g" | cut -d'_' -f1 > ./labidlist.txt
	header="central_sample_id,adm1,received_date,collection_date,source_age,source_sex,is_surveillance,collection_pillar,is_hcw,employing_hospital_name,employing_hospital_trust_or_board,is_hospital_patient,is_icu_patient,admitted_with_covid_diagnosis,admission_date,admitted_hospital_name,admitted_hospital_trust_or_board,is_care_home_worker,is_care_home_resident,anonymised_care_home_code,adm2,adm2_private,biosample_source_id,root_sample_id,sender_sample_id,collecting_org,sample_type_collected,sample_type_received,swab_site,epi_cluster,investigation_name,investigation_site,investigation_cluster,majora_credit,ct_1_ct_value,ct_1_test_target,ct_1_test_platform,ct_1_test_kit,ct_2_ct_value,ct_2_test_target,ct_2_test_platform,ct_2_test_kit,library_name,library_seq_kit,library_seq_protocol,library_layout_config,library_selection,library_source,library_strategy,library_layout_insert_length,library_layout_read_length,barcode,artic_primers,artic_protocol,run_name,instrument_make,instrument_model,start_time,end_time,flowcell_id,flowcell_type,sequencing_org_received_date,bioinfo_pipe_name,bioinfo_pipe_version"
	outfile=` echo "/data/encrypted2/outputs/metadata_files/"$foldername".metadata.csv"`
	echo $header > $outfile

	# assign COG-UK ID
	for sample in `cat ./labidlist.txt`
	do
		count=`cat $keyfile | wc -l`
		count=$((count+1))
		id=`echo "SCOT-"$count`
		echo "\""$sample"\","$id >> $keyfile
		echo $id",UK-SCT,\""$sample"\",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"$runname",Illumina COVIDSeq,Internal COVIDSeq,PAIRED,PCR,VIRAL_RNA,AMPLICON,,,,,,"$foldername",ILLUMINA,NexSeq2000,,,,,,ARTICNFV3,v1" >> $outfile
	done

	# cleanup
	rm -r $workingdir

	# move folders when done
	mv /data/encrypted2/inbox/*summary_qc_GGC /date/encrypted2/outputs/
done

