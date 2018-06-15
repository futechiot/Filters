close all;

samplefreq = 44100;
filter_type = 'butter';
order = 6;
number_of_bands = 10;


min_freq = 80;
max_freq = 15000;
b = log(max_freq/min_freq)/(number_of_bands-1);
frequencies = min_freq * exp((0:number_of_bands-1).*b);

filters = [];
d = fdesign.lowpass('N,F3dB',order,frequencies(1),samplefreq);
filters = [filters design(d, filter_type)];
for i = 1:number_of_bands-1
    d = fdesign.bandpass('N,F3dB1,F3dB2',order,frequencies(i),frequencies(i+1),samplefreq);
    filters = [filters design(d,filter_type)];
end
d = fdesign.highpass('N,F3dB',order,frequencies(number_of_bands),samplefreq);
filters = [filters design(d, filter_type)];

fvtool(filters);
set(gca, 'XScale', 'log');
axis([0.02, samplefreq/2000 -60 6]);

fileID = fopen('Coefficients.h','w');

fprintf(fileID, 'constexpr int filterSampleRate = %d;\n\n',samplefreq);
fprintf(fileID, 'constexpr int numberOfBands = %d;\n\n',number_of_bands);
fprintf(fileID, 'constexpr int numberOfBiQuads= %d;\n\n',number_of_biquads);

number_of_biquads = ceil(order/2);
fprintf(fileID, 'const double sos_matrices[][numberOfBiQuads][6] = {\n'); 
for i = 1:number_of_bands
    fprintf(fileID, '    {\n');
    SOS_matrix = filters(i).coefficients{1,1};
    for row = SOS_matrix.'
        fprintf(fileID, '        {');
        for coeff = row
            fprintf(fileID, '%.16e, ', coeff);
        end
        fprintf(fileID, '},\n');
    end
    fprintf(fileID, '    },\n');
end
fprintf(fileID, '};\n\n');

fprintf(fileID, 'const double gain[][numberOfBiQuads] = {\n'); 
for i = 1:number_of_bands
    fprintf(fileID, '    {');
    gain_array = filters(i).coefficients{1,2}(1:number_of_biquads);
    for gain = gain_array
        fprintf(fileID, '%.16e, ', gain);
    end
    fprintf(fileID, '},\n');
end
fprintf(fileID, '};\n\n');
