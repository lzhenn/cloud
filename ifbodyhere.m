%------------------------------Function IFBODYHERE()------------------------------
function [X,Y,bflag,bsize]=ifbodyhere(I,sunh,tstr)
%IFBODYHERE: Judge whether there is a MAJOR celestial body (Moon&Sun) on the sky
%	INPUT:
%		I:	the image possibly contains a major celestial body
%	OUTPUT:
%		body_X:	the X coordinate of the celestial body
%		body_Y:	the Y coordinate of the celestial body
%		bflag:	whether the celestial body is in the image with 1 for 'yes' and 0 for 'no'
%	EXAMPLE:
%		[body_X,body_Y,bflag]=ifbodyhere(im,dnflag,lnflag)

%LOG:
%2012-10-14:	Complete
%2013-07-18:	Version.2 gray threshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 		
	X=0;
	Y=0;
	bflag=0;
	bsize=0;
	I=rgb2gray(I);
	I=im2bw(I,0.98);
	if sunh>0
		check_r=245;	
	else	
		check_r=200;
	end

	try
		L=bwlabel(I);
		stats=regionprops(L,'Area');					%Get every labels' Area
		allArea=[stats.Area];				
		allArea=sort(allArea,'descend');
		len=length(allArea);
		if(max(allArea)>=256)
			idx=find([stats.Area]==max(allArea));			%Find the label which take the max area
		end
		s=regionprops(L,'centroid');					%Find every labels' Centroid
		centroids=cat(1,s.Centroid);

		if(round(sqrt((centroids(idx,1)-245)^2+(centroids(idx,2)-245)^2))<check_r)	%If not the light of Guangzhou or Lab, return celestial body result
			bflag=1;
			X=centroids(idx,1);
			Y=centroids(idx,2);
			bsize=max(allArea);
		end
	
	catch
		return
	end
