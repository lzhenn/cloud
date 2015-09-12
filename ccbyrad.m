%------------------------------Function CCBYRAD()------------------------------
function radcc=ccbyrad(sunh,tstr,lastrad,bkcc)
%CCBYRAD: Assisted to judge the Cloud_Cover by radiation of the whole sky
%	INPUT:
%		sunh:	the sunheight now
%	OUTPUT:
%		cc:	Cloud-Cover caculated by radiation
%	EXAMPLE:
%		 cc=ccbyrad(sunh)

%LOG:
%2012-10-15:	Complete
%2013-05-25:	Update to version.2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

	lon=113.39*pi/180;
	lat=23.05*pi/180;
	rad=1400;					%define 1400W/m^2 which is beyond the parameter of sun radiation as the default value of rad in case no result in zdqdata
	
	mday=[31 28 31 30 31 30 31 31 30 31 30 31];
	mon=str2num(tstr(5:6));
	dn=sum(mday(1:mon-1))+str2num(tstr(7:8));
	
	try	
		fid1=fopen(['../data/GD',tstr(3:8),'.DAT'],'r');

        tnow=str2num(tstr(9:10))*60+str2num(tstr(11:12));
        ipos=1;

        while(~feof(fid1))
            line=fgetl(fid1);	
            tpos=str2num(line(9:10))*60+str2num(line(11:12));
            if(tnow-tpos<60)
                radt(ipos)=tpos;
                rad(ipos)=str2num(line(309:312));
                ipos=ipos+1;
                if(tnow-tpos<=0)
                    break;
                end
            end
        end
        fclose(fid1);
	
        maxpos=ipos-1;
        for i=1:maxpos
            HA=((radt(i)/60)*15-300)*pi/180+lon;
            theta0=(360*dn/365)*pi/180;
            delta=(0.006918-0.399912*cos(theta0)+0.070257*sin(theta0)-0.006758*cos(2*theta0)+0.000907*sin(2*theta0)-0.002697*cos(3*theta0)+0.00148*sin(3*theta0));
            sunh(i)=asin(sin(lat)*sin(delta)+cos(lat)*cos(delta)*cos(HA))*180/pi;
            radth(i)=-0.0019*sunh(i)^3+0.1973*sunh(i)^2+8.4455*sunh(i)-37.1084;
        end
        drad=radth-rad;
        p=polyfit([1:ipos-1],drad,1);
        remain=polyval(p,[1:maxpos]);	%trendency off
        radfit=drad-remain;
        if (drad(maxpos)/radth(maxpos))>0.5
            radcc=1;
        elseif(drad(maxpos)/radth(maxpos))<0.2
            radcc=0;
        else
            if(max(abs(radfit))<=15)
                radcc=0;
            else
                radcc=0.5;
            end
        end
	catch
		radcc=0.5;
	return;
end	

