/*
    g++ -std=c++11 -fopenmp *.cpp

    Requires AudioFile library: https://github.com/adamstark/AudioFile
*/
#include "AudioFile.h"

#include "../src/SOSFilter.h"

#include <iostream>
using namespace std;

#include "Coefficients.h"

void filter(AudioFile<double> &source, int index);

int main() {
    AudioFile<double> source;
    AudioFile<double> outputs[numberOfBands];

    source.load("input.wav");
    int sampleRate = source.getSampleRate();
    assert(sampleRate == filterSampleRate);

    #pragma omp parallel for
    for (int i = 0; i < numberOfBands; i++) {
        filter(source, i);
    }

    return 0;
}

void filter(AudioFile<double> &source, int index) {
    AudioFile<double> output;
    int sampleRate = source.getSampleRate();
    int numChannels = source.getNumChannels();
    int numSamples = source.getNumSamplesPerChannel();
    int bitDepth = source.getBitDepth();

    output.setAudioBufferSize(numChannels, numSamples);
    output.setBitDepth(bitDepth);
    output.setSampleRate(sampleRate);

    Filter **filters = new Filter*[numChannels];
    for (int channel = 0; channel < numChannels; channel++)
        filters[channel] = new SOSFilter<numberOfBiQuads>(sos_matrices[index], gain[index]);

    for (int sample = 0; sample < numSamples; sample++) {
        for (int channel = 0; channel < numChannels; channel++) {
            output.samples[channel][sample] =
                filters[channel]->filter(source.samples[channel][sample]);
        }
    }

    char name[32] = "";
    snprintf(name, 32, "output_%d.wav", index + 1);
    output.save(name);

    for (int channel = 0; channel < numChannels; channel++)
        delete filters[channel];
    delete[] filters;
}