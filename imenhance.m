%------------------------------Function IMENHANCE()------------------------------
function im=imenhance(im0)
%IMENHANCE: Enhance the img in order to get rid of noise
%	INPUT:
%		im0: the read img after geometrical process
%	OUTPUT:
%		im: the img that after enhanced process
%	EXAMPLE:
%		im=imenhance()

%LOG:
%2012-08-14:	Complete
%2012-10-03:	Modify the description and comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	

	im0=rgb2gray(im0);						%Rgb2gray passage <Next:RGB Threshold?>

	imwrite(im0,'data/Before_Enhance_Gray.png');

	[im0 noise]=wiener2(im0,[5 5]);					%Wiener enhance
	se =strel('disk',15);
	Itop=imtophat(im0,se);						%Top_hat transform
	Ibot=imbothat(im0,se);						%Bottom_hat transform
	im0=imsubtract(imadd(Itop,im0),Ibot);				%Top_hat-Bottom_hat, enhance the pic again
	im=imcomplement(im0);						%Film transform <No Use?>

	imwrite(im,'data/After_Enhance_Gray.png');
