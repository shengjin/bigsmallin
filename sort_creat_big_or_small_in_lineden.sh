#!/bin/bash
#
#Shell script to creat the "big/small.in" file for Mercury6.
#The output file is "$filename(big/small).in" and "AMIED.txt"(au, mass, inclination, eccentricity) for plot.
#This script requires a "init.txt" file,
#Make sure there is no "$filename(big/small).in" or "AMIED.txt" in the directory before you run it.

############################ header

filename=`awk '/^filename/ {print $2}' init.txt`

if [ -e $filename ]
then
	echo " '$filename' already exist! Please move it to another directory!"
	exit 1
elif  [ -e AMIED.txt ]
then
	echo " 'AMIED.txt' already exist! Please move it to another directory!"
	exit 1
fi

echo ")O+_06 Big-body initial data  (WARNING: Do not  delete this EmbroingShu!!)" >> $filename
echo ") Lines beginning with ) are ignored" >> $filename
echo ")------------------------------------------------------------------------------" >> $filename
echo " style (Cartesian, Asteroidal, Cometary) =        Asteroidal" >> $filename

#epoch for big.in
if [ $filename == big.in ]
then
	epoch_indays=`awk '/^epoch_indays/ {print $2}' init.txt`
	echo " epoch (in days) = $epoch_indays" >> $filename
fi

echo ")------------------------------------------------------------------------------" >> $filename
echo ")Mercury6 Initial File, `date`" >> $filename
echo ")------------------------------------------------------------------------------" >> $filename

############################# big planet
bignumber=`awk '/^bignumber/ {print $2}' init.txt`

if [ $bignumber != 0 ]
then
	localbignum=1
	while [ $localbignum -le $bignumber ]
	do
		sed -ne '/^GP0*'"$localbignum"' .*/ {
		p
		n
		p
		n
		p
		n
		p }' ./init.txt >> big.in 
		localbignum=`expr $localbignum + 1`
	done
fi

snowline=`awk '/^snowline/ {print $2}' init.txt`
is_density_begin=`awk '/^is_density_begin/ {print $2}' init.txt`
is_density_end=`awk '/^is_density_end/ {print $2}' init.txt`
os_density_begin=`awk '/^os_density_begin/ {print $2}' init.txt`
os_density_end=`awk '/^os_density_end/ {print $2}' init.txt`

au_powerlaw=`awk '/^au_powerlaw/ {print $2}' init.txt`

########################### equal mass
bodynumber=`awk '/^bodynumber/ {print $2}' init.txt`
if [ $bodynumber != 0 ]
then
	bodymass_earth=`awk '/^bodymass_earth/ {print $2}' init.txt`
	a_begin=`awk '/^a_begin/ {print $2}' init.txt`
	a_end=`awk '/^a_end/ {print $2}' init.txt`
	e_range=`awk '/^e_range/ {print $2}' init.txt`
	i_range=`awk '/^i_range/ {print $2}' init.txt`
	
	awk '
	BEGIN {
		srand()
		random_threshold='"$a_begin"'^'"$au_powerlaw"'*1.1
		Embro=1
		while (Embro <= '"$bodynumber"' ) {
			AuX2=rand()*random_threshold
			a_range='"$a_end"'-'"$a_begin"'
			AuX1=rand()*a_range+'"$a_begin"'
			if (AuX2 < AuX1^('"$au_powerlaw"')) {
				Auarray['"$bodynumber"']=AuX1
				printf"%12.11e\n", Auarray['"$bodynumber"'] >> "temp"
				print Embro >> "nutemp"
				++Embro
			}
		}
	}
	'
	sort -g temp > autemp
	rm temp
	paste nutemp autemp > nuau
	rm nutemp
	rm autemp
	
	sleep 1
	
	awk '
	{
		AuX[$1]=$2
	}
	END {
		srand()
		Embro=1
		while (Embro <= '"$bodynumber"' ) {
			is_density_range='"$is_density_end"'-'"$is_density_begin"'
			if (AuX[Embro] < '"$snowline"')
				DenX=-(AuX[Embro]-'"$a_begin"')*is_density_range/('"$snowline"'-'"$a_begin"')+'"$is_density_end"'
			else 
				DenX=-(AuX[Embro]-'"$snowline"')*('"$os_density_end"'-'"$os_density_begin"')/('"$a_end"'-'"$snowline"')+'"$os_density_end"'
			if (Embro < 10) 
				Prefix = "EM0000"
			else if (Embro < 100)
				Prefix = "EM000"
			else if (Embro < 1000)
				Prefix = "EM00"
			else if (Embro < 10000)
				Prefix = "EM0"
			else 
				Prefix = "EM"
			MassX=(3.04043264264672381E-06*'"$bodymass_earth"')
			if (MassX > 0.4E-7)
				printf "%s%d m=%12.11E r=%2.1f d=%3.2f\n", Prefix, Embro, MassX, 0.1, DenX >> "'"$filename"'"
			else
				printf "%s%d m=%12.11E r=%2.1f d=%3.2f\n", Prefix, Embro, MassX, 0.0, DenX >> "'"$filename"'"
			Incli=rand()*'"$i_range"'
			Eccen=rand()*'"$e_range"'
			printf"%12.11E %12.11E %12.11E\n %12.11E %12.11E %12.11E\n %12.11E %12.11E %12.11E\n",AuX[Embro],Eccen,Incli,rand()*360,rand()*360,rand()*360,0,0,0 >> "'"$filename"'"
			printf"%12.11E %12.11E %12.11E %12.11E %12.11E\n", AuX[Embro], MassX, Incli, Eccen, DenX >> "AMIED.txt"
			++Embro
			}
	}
	' nuau
	rm nuau
fi

sleep 1

################################# unequal mass
ne_bodynumber=`awk '/^ne_bodynumber/ {print $2}' init.txt`
if [ $ne_bodynumber != 0 ]
then
	ne_mass_earth_rand_in=`awk '/^ne_mass_earth_rand_in/ {print $2}' init.txt`
	ne_mass_earth_rand_out=`awk '/^ne_mass_earth_rand_out/ {print $2}' init.txt`
	ne_mass_earth_ScaleWithAU=`awk '/^ne_mass_earth_ScaleWithAU/ {print $2}' init.txt`
	ne_a_begin=`awk '/^a_begin/ {print $2}' init.txt`
	ne_a_end=`awk '/^a_end/ {print $2}' init.txt`
	ne_e_range=`awk '/^e_range/ {print $2}' init.txt`
	ne_i_range=`awk '/^i_range/ {print $2}' init.txt`
	
	awk '
	BEGIN {
		srand()
		random_threshold='"$ne_a_begin"'^'"$au_powerlaw"'*1.1
		Embro=1
		while (Embro <= '"$ne_bodynumber"' ) {
			AuX2=rand()*random_threshold
			a_range='"$ne_a_end"'-'"$ne_a_begin"'
			AuX1=rand()*a_range+'"$ne_a_begin"'
			if (AuX2 < AuX1^('"$au_powerlaw"')) {
				Auarray['"$ne_bodynumber"']=AuX1
				printf"%12.11e\n", Auarray['"$ne_bodynumber"'] >> "temp"
				print Embro >> "nutemp"
				++Embro
			}
		}
	}
	'
	sort -g temp > autemp
	rm temp
	paste nutemp autemp > nuau
	rm nutemp
	rm autemp
	
	sleep 1
	
	awk '
	{
		AuX[$1]=$2
	}
	END {
		srand()
		Embro=1
		while (Embro <= '"$ne_bodynumber"' ) {
			is_density_range='"$is_density_end"'-'"$is_density_begin"'
			if (AuX[Embro] < '"$snowline"')
				DenX=-(AuX[Embro]-'"$a_begin"')*is_density_range/('"$snowline"'-'"$a_begin"')+'"$is_density_end"'
			else 
				DenX=-(AuX[Embro]-'"$snowline"')*('"$os_density_end"'-'"$os_density_begin"')/('"$a_end"'-'"$snowline"')+'"$os_density_end"'
			if (Embro < 10) 
				Prefix = "NE0000"
			else if (Embro < 100)
				Prefix = "NE000"
			else if (Embro < 1000)
				Prefix = "NE00"
			else if (Embro < 10000)
				Prefix = "NE0"
			else 
				Prefix = "NE"
			ne_mass_randrange='"$ne_mass_earth_rand_out"'-'"$ne_mass_earth_rand_in"'
			MassX=3.04043264264672381E-06*(rand()*ne_mass_randrange+'"$ne_mass_earth_rand_in"')*(AuX[Embro]^'"$ne_mass_earth_ScaleWithAU"')
			if (MassX > 0.4E-7)
				printf "%s%d m=%12.11E r=%2.1f d=%3.2f\n", Prefix, Embro, MassX, 0.1, DenX >> "'"$filename"'"
			else
				printf "%s%d m=%12.11E r=%2.1f d=%3.2f\n", Prefix, Embro, MassX, 0.0, DenX >> "'"$filename"'"
			Incli=rand()*'"$ne_i_range"'
			Eccen=rand()*'"$ne_e_range"'
			printf"%12.11E %12.11E %12.11E\n %12.11E %12.11E %12.11E\n %12.11E %12.11E %12.11E\n",AuX[Embro],Eccen,Incli,rand()*360,rand()*360,rand()*360,0,0,0 >> "'"$filename"'"
			printf"%12.11E %12.11E %12.11E %12.11E %12.11E\n", AuX[Embro], MassX, Incli, Eccen, DenX >> "AMIED.txt"
			++Embro
			}
	}
	' nuau
	rm nuau
fi


############################## show total mass
TotEmMass=`awk '{sum+=$2}; END{print sum}' AMIED.txt`
echo "total mass of the bodies (except big planets) are : $TotEmMass (in solar mass)"
exit
