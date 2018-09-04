#include <stdio.h>

void printseed(unsigned char* data) {
	int i;
	for(i=1;i<16;i++) {
		printf("%x ", data[i]);
	}
	printf("\n");
}

void printstream(unsigned char* data, int restart) {
	int i;
	for(i=restart;i<16;i++) {
		printf("%d ", data[i]&1);
	}
	printf("\n");
}
#define CARRY	if(a>0x0f) {\
			a &= 0xf;\
			carry=1;\
		} else carry=0;

void mangle(unsigned char* data) {
	unsigned char a,x,temp,i,offset,carry=0;
	a=data[0xf];
	do {
		x=a;
		offset=1;
		carry=1;
		a+=data[offset]+carry;
		data[offset]=a&0xf;
		a=data[offset++];
		a+=data[offset]+carry;
		a=(~a)&0xf;
		temp=a; a=data[offset]; data[offset++]=temp&0xf;
		a+=data[offset]+carry;
		if(a<0x10) {
			temp=a; a=data[offset]; data[offset++]=temp&0xf;
		}
		a+=data[offset];
		data[offset]=a&0xf;
		a=data[offset++];
		carry=0;
		a+=data[offset]+carry;
		temp=a; a=data[offset]; data[offset++]=temp&0xf;
		a+=8;
		if(a<0x10) {
			a+=data[offset]+carry;
		}
		temp=a; a=data[offset]; data[offset++]=temp&0xf;

		while(offset<0x10) {
			a++;
			a+=data[offset]+carry;
			data[offset]=a&0xf;
			a=data[offset++];
		}
		offset &= 0xf;
		a=x;
		a+=0xf;
		CARRY;
	} while(carry);
}

int main(int argc, char **argv) {
	unsigned char *label[2];
	unsigned char restart = 1, swap = 0;
	long streamno = 0;
	char *endptr;
	unsigned char lockseed[16]={0x0, // dummy
				 0xb,0x1,0x4,0xf,
				 0x4,0xb,0x5,0x7,
				 0xf,0xd,0x6,0x1,
				 0xe,0x9,0x8};
	unsigned char keyseed[16]={0x0, // dummy
				 0x0, // fill-in value sent by lock on reset in bit order 3-0-1-2
				 0x9,0xa,0x1,
				 0x8,0x5,0xf,0x1,
				 0x1,0xe,0x1,0x0,
				 0xd,0xe,0xc};

	if(argc < 2) {
		printf("Usage: %s <stream number>\n\n", argv[0]);
		printf("<stream number> selects one of 16 fill-in values sent by the lock on reset.\n");
		printf("Both sides use it as the first nibble of the seed initially sent on D1 by\n");
		printf("the lock. Transmission bit order is 3-0-1-2. e.g. '1-0-1-1' => 0xe\n");
		return -1;
	}

	streamno = strtol(argv[1], &endptr, 0);
	printf("%p %p\n", argv[1], endptr);
	if(*endptr) {
		printf("invalid format for stream number. example: decimal: 15, hex: 0xe, oct: 017\n");
		return 1;
	}
	if(streamno > 15 || streamno < 0) {
		printf("invalid stream number. Valid range is 0x0-0xf\n");
		return 1;
	}
	keyseed[1] = (unsigned char) streamno;
	printf("initial seeds:\n");
	printseed(lockseed);
	printseed(keyseed);
	printf("\n");

	label[0] = "LockOutKeyIn";
	label[1] = "LockInKeyOut";
while(1) {
	printf("\n");
	printf("D0[%s]: ", label[0]);
	printstream(swap ? keyseed : lockseed, restart);
	printf("D1[%s]: ", label[1]);
	printstream(swap ? lockseed : keyseed, restart);
	mangle(keyseed);
	mangle(keyseed);
	mangle(keyseed);
	mangle(lockseed);
	mangle(lockseed);
	mangle(lockseed);

//printseed(keyseed);
//printseed(lockseed);
	restart = keyseed[7];
	swap = restart & 1;
	if(swap) {
		label[0] = "LockInKeyOut";
		label[1] = "LockOutKeyIn";
	} else {
		label[0] = "LockOutKeyIn";
		label[1] = "LockInKeyOut";
	}
//	lockseed[3]=lockseed[7];
	if(!restart)restart=1;
//	printf("send %d-15\n", restart);
}
	return 0;
}
