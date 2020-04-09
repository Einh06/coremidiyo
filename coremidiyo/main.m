//
//  main.m
//  coremidiyo
//
//  Created by Florian Morel on 09.04.20.
//  Copyright © 2020 Florian Morel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct my_player_s {
    AUGraph graph;
    AudioUnit instrument;
} my_player_t;

void myMidiMessageProc(MIDINotification *message, void *userData) {
    
}

void myMidiReadProc(MIDIPacketList *pktList, void *readProcContext, void *srcConnectContext) {
    MIDIPacket *packet = (MIDIPacket *)pktList->packet;
    
    for (int i = 0; i < pktList->numPackets; ++i) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        Byte midiChannel = midiStatus & 0x0F;
        printf("Command: %x, Channel: %x\n", midiCommand, midiChannel);
        packet = MIDIPacketNext(packet);
    }
}

void setupAUGraph(my_player_t *player) {
    // all kind of shit goes there
}

void setupMidi(my_player_t *player) {
    MIDIClientRef client = {0};
    assert( noErr == MIDIClientCreate(CFSTR("CoreMidi demo"),
                                      myMidiMessageProc,
                                      player,
                                      &client));
    
    MIDIPortRef inPort = {0};
    assert(noErr == MIDIInputPortCreate(client,
                                        CFSTR("Input port"),
                                        myMidiReadProc,
                                        player,
                                        &inPort));
    
    int sourceCount = (int)MIDIGetNumberOfSources();
    printf("%d sources\n", sourceCount);
    
    for (int i = 0; i < sourceCount; ++i) {
        MIDIEndpointRef src = MIDIGetSource(i);
        CFStringRef endpointName = NULL;
        assert(noErr == MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName));
        
        char buffer[256] = {0};
        CFStringGetCString(endpointName, buffer, sizeof(buffer), kCFStringEncodingUTF8);
        printf("Source Name, %s\n", buffer);
        assert(noErr == MIDIPortConnectSource(inPort, src, NULL));
    }
}

int main(int argc, const char * argv[]) {
    
    my_player_t player;
    
    setupAUGraph(&player);
    setupMidi(&player);
    
    CFRunLoopRun();
    return 0;
}
