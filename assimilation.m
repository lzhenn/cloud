%------------------------------Function 	ASSIMILATION()------------------------------
function bca=assimilation()
%ASSIMILATION: Judge the basic cloud cover condition by CEILING
%	INPUT:
%
%	OUTPUT:
%		bca:	background cloud cover caculated by CEILING
%	SUBFUNCION:
%		METARS:	Read and process the metar of ZGGG
%	EXAMPLE:
%		bca=assimilation()	

%LOG:
%2013-01-23:	Completed METARs method
%2013-05-24:	Update METARs method to a reasonable condition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
	fprintf('        >>>>  Threshold Judgement, Assimilation module...\n')
	fid=fopen('../cloud_ceil.dat','r');
	line=fgets(fid);
	maxl=length(line);
	bca=str2num(line(26:maxl));
