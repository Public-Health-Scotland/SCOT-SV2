for file in /data/encrypted/inbox/*summary_qc_*/*.csv
do

        # clean up IDs and set up files
        keyfile="/data/encrypted/keyfile/keyfile.txt"
        foldername=`echo $file | rev | cut -d '/' -f1 | rev | sed "s/_summary_qc_.*.csv//g"`
        runname=`ls -ld /data/encrypted/outputs/*$foldername | grep "$foldername" | cut -d'_' -f2`
        timestamp=$(date +%s)
        cp $keyfile $keyfile.$foldername.$timestamp
        workingdir="/data/encrypted/workingdir/scratch/CLIMB_prep"
        mkdir $workingdir
        cd $workingdir
        header="central_sample_id,adm1,received_date,collection_date,source_age,source_sex,is_surveillance,collection_pillar,is_hcw,employing_hospital_name,employing_hospital_trust_or_board,is_hospital_patient,is_icu_patient,admitted_with_covid_diagnosis,admission_date,admitted_hospital_name,admitted_hospital_trust_or_board,is_care_home_worker,is_care_home_resident,anonymised_care_home_code,adm2,adm2_private,biosample_source_id,root_sample_id,sender_sample_id,collecting_org,sample_type_collected,sample_type_received,swab_site,epi_cluster,investigation_name,investigation_site,investigation_cluster,majora_credit,ct_1_ct_value,ct_1_test_target,ct_1_test_platform,ct_1_test_kit,ct_2_ct_value,ct_2_test_target,ct_2_test_platform,ct_2_test_kit,library_name,library_seq_kit,library_seq_protocol,library_layout_config,library_selection,library_source,library_strategy,library_layout_insert_length,library_layout_read_length,barcode,artic_primers,artic_protocol,run_name,instrument_make,instrument_model,start_time,end_time,flowcell_id,flowcell_type,sequencing_org_received_date,bioinfo_pipe_name,bioinfo_pipe_version"
        outfile=` echo "/data/encrypted/outputs/metadata_files/"$foldername".metadata.csv"`
        sed -i "s/\r*$//g" $file
        sed -i "s/ //g" $file
        echo $header > $outfile


        # make file with IDs including cleaned up lab ID and sample ID from Illumina
        touch ./samplelist.txt

        if [[ "$file" == *"GGC"* ]]; then

                for sample in `cat $file | awk -vFPAT='([^,]*)|("[^"]+")' -vOFS=, '{if ($21 == "Y") print $1;}'`
                do
                        cleanid=`echo $sample | sed "s/^V/V,/g" | sed "s/_/\./g" | sed "s/\.S[[:digit:]]/_/g" | cut -d'_' -f1`
                        echo $cleanid"@"$sample >> ./samplelist.txt
                done
        fi

        if [[ "$file" == *"EDB"* ]]; then

                for sample in `cat $file | awk -vFPAT='([^,]*)|("[^"]+")' -vOFS=, '{if ($21 == "Y") print $1;}'`
                do
                        cleanid=`echo $sample | sed "s/_/\./g" | sed "s/\.S[[:digit:]]/_/g" | cut -d'_' -f1 | sed "s/\./_/g"`
                        echo $cleanid"@"$sample >> ./samplelist.txt
                done
        fi


        # create Consensus folder
        cons_folder=`echo "/data/encrypted/outputs/consensus_sequences/"$foldername`
        mkdir $cons_folder

        # assign SCOT ID and organise consensus folder while changing fasta header
        for sample in `cat ./samplelist.txt`
        do
                count=`cat $keyfile | wc -l`
                count=$((count+1))
                id=`echo "SCOT-"$count`
                cleansample=`echo $sample | cut -d'@' -f1`
                illuminaname=`echo $sample | cut -d'@' -f2`
                echo "\""$cleansample"\","$id","$illuminaname >> $keyfile
                mkdir $cons_folder/$id
                echo $id",UK-SCT,\""$cleansample"\",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,"$runname",Illumina COVIDSeq,Internal COVIDSeq,PAIRED,PCR,VIRAL_RNA,AMPLICON,,,,,,"$foldername",ILLUMINA,NexSeq2000,,,,,,ARTICNFV3,v1" >> $outfile
                cp /data/encrypted/results/$foldername/ncovIllumina_sequenceAnalysis_makeConsensus/$illuminaname.*fa $cons_folder/$id/$id.fa
                header=">PHMBI\/"$id"\/SCOT\:"$foldername
                sed -i "1s/.*/$header/" $cons_folder/$id/$id.fa
        done

        # merge consensus file to single file
        cat /data/encrypted/outputs/consensus_sequences/$foldername/*/*.fa > /data/encrypted/outputs/consensus_sequences/$foldername/$foldername.fa

        # send sequences to genomics01
        mkdir /data/encrypted/outbox/vmware/$foldername
        cp /data/encrypted/outputs/consensus_sequences/$foldername/$foldername.fa /data/encrypted/outbox/vmware/$foldername/
        cp $outfile /data/encrypted/outbox/vmware/$foldername/
        touch /data/encrypted/outbox/vmware/$foldername.ready

        # cleanup
        rm -r $workingdir

        # move folders when done
        mv /data/encrypted/inbox/$foldername*summary_qc_* /data/encrypted/outputs/
done