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

MIDIPortRef outputPort;
MIDIEndpointRef destEndpoint;

typedef struct my_player_s {
    AUGraph graph;
    AudioUnit instrument;
} my_player_t;

typedef enum {

    LPM_Session = 108,
    LPM_User1 = 109,
    LPM_User2 = 110,
    LPM_Mixer = 111,

} LaunchPadMini_Keys;

void myMidiMessageProc(MIDINotification *message, void *userData) {
    
}

void myMidiReadProc(MIDIPacketList *pktList, void *readProcContext, void *srcConnectContext) {
    MIDIPacket *packet = (MIDIPacket *)pktList->packet;
    
    for (int i = 0; i < pktList->numPackets; ++i) {
        Byte midiStatus = packet->data[0];
        Byte midiCommand = midiStatus >> 4;
        Byte midiChannel = midiStatus & 0x0F;
        printf("Command: %x, Channel: %x\n", midiCommand, midiChannel);
        if (midiCommand == 0x08 || midiCommand == 0x09) {
            Byte note = packet->data[1] & 0x7F;
            Byte velocity = packet->data[2] & 0x7F;
            printf("Note: %d, Velocity: %d\n", note, velocity);
        }
        if (midiCommand == 0x0b) {
            Byte controllerNumber = packet->data[1] & 0x7F;
            Byte controllerValue = packet->data[2] & 0x7F;

            printf("Controller: %d, Value: %d\n", controllerNumber, controllerValue);
        }
        if (midiCommand == 0x0e) {
            Byte LSB = packet->data[1] & 0x7F; // 7bits
            Byte MSB = packet->data[2] & 0x7F; // 7bits
            uint16_t LSB_16 = (uint16_t)LSB; // 0000 0000 0LLL LLLL
            uint16_t MSB_16 = (uint16_t)MSB; // 0000 0000 0MMM MMMM
            uint16_t shifted_MSB_16 = MSB_16 << 7; // 00MM MMMM M000 0000
            uint16_t val = shifted_MSB_16 | LSB_16; // 00MM MMMM MLLL LLLL
//            if (val < 0x2000) //less pitch bend
//            if (val > 0x2000) //more pitch bend
                
            printf("Pitch Bend Value: %x\n", val);
        }
        packet = MIDIPacketNext(packet);
    }

    MIDISend(outputPort, destEndpoint, pktList);
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

    assert(noErr == MIDIOutputPortCreate(client, CFSTR("Output port"), &outputPort));

    int destCount = (int)MIDIGetNumberOfDestinations();
    printf("%d destinations\n", destCount);
    for (int i = 0; i < destCount; ++i) {

        MIDIEndpointRef dest = MIDIGetDestination(i);

        CFStringRef endpointName;
        assert(noErr == MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &endpointName));

        char buffer[256] = {0};
        CFStringGetCString(endpointName, buffer, sizeof(buffer), kCFStringEncodingUTF8);
        printf("Destination Name, %s\n", buffer);

        destEndpoint = dest;
    }
}

int main(int argc, const char * argv[]) {
    
    my_player_t player;
    
    setupAUGraph(&player);
    setupMidi(&player);
    
    CFRunLoopRun();
    return 0;
}
