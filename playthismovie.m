function [  ] = playthismovie( movie_array, fpss )
%PLAYTHISMOVIE Summary of this function goes here
%   Detailed explanation goes here



scrsz = get(0,'ScreenSize');

figure('Position',[1 scrsz(4)/2.2 scrsz(3) scrsz(4)/2],... #figure 3
                            'Toolbar', 'none');    

set(gca,'Position',[0 0 1 1]);   

movie(movie_array,1,fpss);

end

