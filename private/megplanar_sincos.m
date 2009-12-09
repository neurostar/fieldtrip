function montage = megplanar_sincos(cfg, grad)

% This attempts to re-implements Ole's method, exept that the definition of the
% horizontal and vertical direction is different.

% Copyright (C) 2004-2009, Robert Oostenveld
%
% Subversion does not use the Log keyword, use 'svn log <filename>' or 'svn -v log | less' to get detailled information

[pnt, ori, lab] = channelposition(grad);
Ngrad = length(lab);
distance = zeros(Ngrad,Ngrad);

for i=1:Ngrad
  for j=(i+1):Ngrad
    distance(i,j) = norm(pnt(i,:)-pnt(j,:));
    distance(j,i) = distance(i,j);
  end
end

fprintf('minimum distance between gradiometers is %6.2f %s\n', min(distance(find(distance~=0))), grad.unit);
fprintf('maximum distance between gradiometers is %6.2f %s\n', max(distance(find(distance~=0))), grad.unit);

% select the channels that are neighbours, channel is not a neighbour of itself
neighbsel = distance<cfg.neighbourdist;
for i=1:Ngrad
  neighbsel(i,i) = 0;
end
fprintf('average number of neighbours is %f\n', sum(neighbsel(:))./size(neighbsel,1));


gradH = zeros(Ngrad, Ngrad);
gradV = zeros(Ngrad, Ngrad);

for chan=1:Ngrad
  % Attach a local coordinate system to this gradiometer:
  % the origin at the location of its bottom coil
  % the z-axis pointing outwards from the head
  % the x-axis pointing horizontal w.r.t. the head
  % the y-axis pointing vertical, i.e. approximately towards the vertex
  this_o = pnt(chan,:);
  this_z = ori(chan,:);          this_z = this_z / norm(this_z);
  this_x = cross([0 0 1], this_z);
  if all(this_x==0)
    this_x = [1 0 0];
  else
    this_x = this_x / norm(this_x);
  end
  this_y = cross(this_z, this_x);

  for neighb=find(neighbsel(chan, :))
    vec = pnt(neighb,:) - this_o;    % vector from sensor to neighbour
    proj_x = dot(vec, this_x);            % projection along x-axis (horizontal)
    proj_y = dot(vec, this_y);            % projection along y-axiz (vertical)
    proj_z = dot(vec, this_z);            % projection along z-axis

    gradH(chan, chan)   = gradH(chan,chan)    - proj_x / (norm(vec).^2);
    gradH(chan, neighb) =                       proj_x / (norm(vec).^2);
    gradV(chan, chan)   = gradV(chan,chan)    - proj_y / (norm(vec).^2);
    gradV(chan, neighb) =                       proj_y / (norm(vec).^2);
  end
end

% rename the labels to match the new channel content
labelH = cell(1, length(lab));
labelV = cell(1, length(lab));
for i=1:length(lab)
  labelH{i} = sprintf('%s_dH', lab{i});
end
for i=1:length(lab)
  labelV{i} = sprintf('%s_dV', lab{i});
end

% construct a montage, i.e. a simple linear projection matrix
montage = [];
montage.labelnew = cat(1, labelH(:), labelV(:));  % describes the rows
montage.labelorg = lab(:)';                       % describes the columns
montage.tra      = cat(1, gradH, gradV);          % this is the linear projection matrix
