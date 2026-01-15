function pdfwrite(figh,fname)

% pdfwrite(figh,fname)
%
% Saves as EPS then converts to PDF using epstopdf.
% (Note that saving as pdf directly puts the figure on a full page.)
%
% INPUTS:
%	figh	figure handle
%	fname	filename (no extension)
%
% Last updated by Bob Kopp rkopp-at-rutgers.edu, 18 May 2014

if nargin==1
        fname=figh;
        figh=gcf;
end

epsfname = [fname '.eps'];
saveas(figh,epsfname,'epsc2');

% Try epstopdf on PATH (including Homebrew), otherwise fall back to MacTeX.
epstopdf_cmd = 'epstopdf';
path_prefix = '/opt/homebrew/bin';
[st,~] = system(['PATH="' path_prefix '":$PATH ; command -v epstopdf']);
if st~=0
    if exist('/Library/TeX/texbin/epstopdf','file')
        epstopdf_cmd = '/Library/TeX/texbin/epstopdf';
    end
end

[st2,out2] = system(['unset LD_LIBRARY_PATH ; PATH="' path_prefix '":$PATH ; ' epstopdf_cmd ' ' epsfname]);
if st2==0
    delete(epsfname);
else
    warning(['pdfwrite: epstopdf failed. Leaving EPS in place: ' epsfname char(10) out2]);
end