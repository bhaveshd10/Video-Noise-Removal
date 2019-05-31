%% Without alignment
clear all;clc;close all

% Read video and extract frames
vidobj = VideoReader('Sky_Noisy.avi');  
numFrames = get(vidobj, 'NumberOfFrames');
for i=1:numFrames
    frame = im2double(read(vidobj, i));     % access each frame
    cell_frame{i}=frame;
end

% Removal of noise by averaging without frame alignment
f_avg1{1}=cell_frame{1};
for t=2:30
    f_avg1{t}= ((t-1)/t)*f_avg1{t-1}+((1/t)*cell_frame{t}); % find average
end

% Display image
figure,imshow(f_avg1{30})
%% With alignment
clear all;clc;close all

% Read Video and extract frames
vidobj = VideoReader('Sky_Noisy.avi');  
numFrames = get(vidobj, 'NumberOfFrames');
for i=1:numFrames
    frame = im2double(read(vidobj, i));
    cell_frame{i}=frame;
end

% Range of values of horizontal and vertical shift
dxrange = -30:30;     % Range to be compared 
dyrange   = -15:15; 
f_avg1=cell_frame;

% Reference frame
frameTformRef=rgb2gray(cell_frame{1});
[height, width, channels] = size(cell_frame{1});
% Get best values of dx and dy
best=[];

%find the minimum error frame
for i=1:60
    minSSE=inf;
    for dx=dxrange
        for dy=dyrange
            A = [1 0 dx; 0 1 dy;0 0 1];
            tform = maketform('affine', A.');  
            frameTform = imtransform(rgb2gray(cell_frame{i}),tform,'XData',[1 width],'YData',[1 height]);
            % SSE to find the best alignment
            frameSSE=sum(sum((frameTform-frameTformRef).^2));
            if frameSSE<minSSE
                minSSE=frameSSE;
                bestDx=dx;
                bestDy=dy;
            end
        end
    end
    % Alignment of frames as per best alignment
    best=[best;[bestDx bestDy]];
    Abest=[1 0 bestDx;0 1 bestDy;0 0 1];
    tformbest = maketform('affine', Abest.');
    bestTform{i} = imtransform(f_avg1{i},tformbest,'XData',[1 width],'YData',[1 height]);
end

% find average of first frame
outputframe{1}=cell_frame{1};
for t=2:60
    outputframe{t}= ((t-1)/t)*outputframe{t-1}+((1/t)*bestTform{t}); 
end

% shift the first frame in opposite direction of the best alignment previously found 
temp=outputframe{60};
for i=1:60 
    shift=best(i,:);
    atemp=[1 0 -shift(1,1);0 1 -shift(1,2);0 0 1];
    ttemp = maketform('affine', atemp.');
    bestforall{i} = imtransform(outputframe{60},ttemp,'XData',[1 width],'YData',[1 height]);
end

% Create Video of noise free frames
movie_obj = VideoWriter('Sky_denoised.avi');
open(movie_obj);
for K = 1 : length(bestforall)
  this_image = bestforall{K};
  writeVideo(movie_obj, this_image);
end
close(movie_obj);