# *- bash -*

# Check the Thot package

# Create directory for temporary files
echo "**** Creating directory for temporary files..."
echo ""
tmpdir=`mktemp -d`
# trap "rm -rf $tmpdir 2>/dev/null" EXIT
echo "Temporary files will be stored in ${tmpdir}"
echo ""

# Create directory for debugging information
debugdir=$tmpdir/debug
mkdir $debugdir

# Create directory for shared information
sdir=`mktemp -d $HOME/thot_installcheck_XXXXXX`

# Print warning about possible resource requirements when the software
# is installed on computer clusters
if [ ${QSUB_WORKS} = "yes" ]; then

    qs_opt="-qs"

    echo "------------------------------------------------------------------------" >&2
    echo "NOTE: package was installed on a PBS cluster, you may need to reserve" >&2
    echo "cluster resources in order to successfully execute the Thot tools." >&2
    echo "" >&2
    echo "To reserve resources for this checking, export the \"qs_par\" variable." >&2
    if [ -z "${qs_par}" ]; then
        echo "Warning: the \"qs_par\" variable is empty." >&2
        echo "Sample initialisations for the \"qs_par\":" >&2
        echo "" >&2
        echo "export qs_par=\"-l pmem=1gb\"" >&2
        echo "export qs_par=\"-l h_vmem=4G,h_rt=10:00:00\"" >&2
    else
        echo "Current value of \"qs_par\": \"${qs_par}\"" >&2
    fi
    echo "" >&2
    echo "Please consider the use of the -qs option with the different tools" >&2
    echo "provided by Thot." >&2
    echo "------------------------------------------------------------------------" >&2
    echo "" >&2
    sleep 5

else
    qs_opt=""
    qs_par=""
fi

# Check thot_lm_train
echo "**** Checking thot_lm_train..."
echo ""
${bindir}/thot_lm_train -c $datadir/toy_corpus/en.train -o $tmpdir/lm -n 4 -unk \
     -tdir $debugdir -sdir $sdir ${qs_opt} "${qs_par}" -debug
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Check thot_tm_train
echo "**** Checking thot_tm_train..."
echo ""
${bindir}/thot_tm_train -s $datadir/toy_corpus/sp.train -t $datadir/toy_corpus/en.train \
    -o $tmpdir/tm -n 5 -tdir $debugdir -sdir $sdir ${qs_opt} "${qs_par}" -debug
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Checking thot_gen_cfg_file
echo "**** Checking thot_gen_cfg_file..."
echo ""
${bindir}/thot_gen_cfg_file $tmpdir/lm/lm_desc $tmpdir/tm/tm_desc > $tmpdir/server.cfg 
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Check thot_smt_tune
echo "**** Checking thot_smt_tune..."
echo ""
${bindir}/thot_smt_tune -c $tmpdir/server.cfg -s $datadir/toy_corpus/sp.dev -t $datadir/toy_corpus/en.dev \
    -o $tmpdir/tune  -tdir $debugdir -sdir $sdir ${qs_opt} "${qs_par}" -debug
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Check thot_prepare_sys_for_test
echo "**** Checking thot_prepare_sys_for_test..."
echo ""
${bindir}/thot_prepare_sys_for_test -c $tmpdir/tune/tuned_for_dev.cfg -t $datadir/toy_corpus/sp.test \
    ${qs_opt} "${qs_par}" -o $tmpdir/systest -tdir $debugdir -sdir $sdir
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Check thot_decoder
echo "**** Checking thot_decoder..."
echo ""
${bindir}/thot_decoder -c $tmpdir/systest/test_specific.cfg -t $datadir/toy_corpus/sp.test \
    -o $tmpdir/thot_decoder_out -sdir $debugdir ${qs_opt} "${qs_par}" -debug
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Check thot_calc_bleu
echo "**** Checking thot_calc_bleu..."
echo ""
${bindir}/thot_calc_bleu -r $datadir/toy_corpus/en.test -t $tmpdir/thot_decoder_out
if test $? -eq 0 ; then
    echo "... Done"
else
    mv $sdir/* $debugdir
    echo "================================================"
    echo " Test failed!"
    echo " See additional information in ${tmpdir}"
    echo " Please report to "${bugreport}
    echo "================================================"
    exit 1
fi

echo ""

# Remove directories for temporaries
echo "*** Remove directories used to store temporary files..."
echo ""
rm -rf $tmpdir
rm -rf $sdir

echo ""
echo "================"
echo "All tests passed"
echo "================"
