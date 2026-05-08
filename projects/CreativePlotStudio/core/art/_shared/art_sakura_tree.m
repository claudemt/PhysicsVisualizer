function art_sakura_tree(ax, depth)
if nargin < 1 || isempty(ax), figure; ax = gca; end
if nargin < 2, depth = 16; end
clear_ax(ax); axis(ax,[-1,5,0,5]); axis(ax,'equal');
set(ax,'XColor','none','YColor','none','Color',[.5,.5,.5]);
T=[1.2;0;pi/2]; a=pi/10; rng('shuffle');
for i=1:depth
    L=.6*.9^i;
    I=randi(25,[1,size(T,2)])>9;
    if i==1, I=false(size(I)); end
    L1=T(:,I); t=L1(3,:);
    R1=L1+[cos(t-a)*L; sin(t-a)*L; t*0-a];
    R2=L1+[cos(t+a)*L; sin(t+a)*L; t*0+a];
    L2=T(:,~I); t=L2(3,:);
    R3=L2+[cos(t)*L; sin(t)*L; t*0];
    T=[R1,R2,R3]; %#ok<AGROW>
    X=[L1(1,:),L1(1,:),L2(1,:); R1(1,:),R2(1,:),R3(1,:)]; X(end+1,:)=nan;
    Y=[L1(2,:),L1(2,:),L2(2,:); R1(2,:),R2(2,:),R3(2,:)]; Y(end+1,:)=nan;
    plot(ax,X(:),Y(:),'Color',[0 0 0]+i*.3/depth,'LineWidth',5*0.8^i);
    if i>depth-2
        scatter(ax,T(1,:),T(2,:),i*2-20,'filled','CData',[.86,.68,.68]/(1-.13*max(0,i-depth+1)));
    end
end
safe_title(ax,'Sakura tree');
end
