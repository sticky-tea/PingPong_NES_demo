; Ping-pong game demo
; for NES
; can be compiled with NESasm 

  .inesprg 1
  .ineschr 1
  .inesmap 0
  .inesmir 2

  .rsset $0000

ball_x .rs 1
ball_y .rs 1

ball_dx .rs 1
ball_dy .rs 1

;first_player_y .rs 1

direction_byte .rs 1
game_over .rs 1

count1 .rs 1
count2 .rs 2

  .bank 0
  .org $C000

RESET:
    SEI          ; disable IRQs
    CLD          ; disable decimal mode
    LDX #$40
    STX $4017    ; disable APU frame IRQ
    LDX #$FF  
    TXS          ; Set up stack
    INX          ; now X = 0
    STX $2000    ; disable NMI
    STX $2001    ; disable rendering
    STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0200, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0300, x
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

LoadPalette:
  LDA $2002
  LDA #$3F
  STA $2006
  LDA #$00
  STA $2006
  LDA #$00
LoadBackgroundPaletteLoop:
  LDA background_palette, x
  STA $2007
  INX
  CPX #$10
  BNE LoadBackgroundPaletteLoop
  LDX #$00
LoadSpritePalleteLoop:
  LDA sprite_palette, x
  STA $2007
  INX
  CPX #$10
  BNE LoadSpritePalleteLoop

    LDX #$00
LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #$10
  BNE LoadSpritesLoop

  LDX #$00
LoadPlayer2Loop:
  LDA player_2, x
  STA $0214, x
  INX
  CPX #$10
  BNE LoadPlayer2Loop

  LDX #$00
LoadCount:
  LDA count1, x
  STA $0225, x
  INX
  CPX #$08
  BNE LoadCount
LoadDots:
  LDA dots, x
  STA $022C, x
  INX
  CPX #$04
  BNE LoadDots

LoadBall:
  LDA ball, x
  STA $0210, x
  INX
  CPX #$04
  BNE LoadBall
  
    LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
    STA $2000
  
    LDA #%00010000   ; enable sprites
    STA $2001
;!

    LDA $0210
    STA ball_y

    LDA $0213
    STA ball_x

    LDA #01
    STA ball_dx
    STA ball_dy

    LDA #01
    STA direction_byte

    LDA #01
    STA game_over

Foreverloop:
  JMP Foreverloop 
ToLatchController2:
  JMP LatchController
PlaySound:
    ;play sound
    LDA #%00000001
    STA $4015
    LDA #%01001111
    STA $4000
    LDA #%11001010
    STA $4001
    LDA #20
    STA $4002
    LDA #%01001110
    STA $4003
    RTS

NMI: 

    LDA #$00
    STA $2003       ; set the low byte (00) of the RAM address
    LDA #$02
    STA $4014       ; set the high byte (02) of the RAM address, start the transfer

    LDA game_over
    CMP #$01
    BEQ ToLatchController2

    LDA count1
    CMP #$05
    BNE Cont1
    JMP GameOver
Cont1:
    LDA count2
    CMP #$05
    BNE Cont2
    JMP GameOver
Cont2:

    LDA ball_x
    CMP #$02
    BCS ContinueNMI1
    INC $0229 ; count++
    INC count1
    LDA #$01
    STA game_over
    LDA #$02;
    STA $0211;
    LDA #$50
    STA $0210
    STA $0213

ContinueNMI1:
    
    LDA ball_x
    CMP #$F0
    BCC ContinueNMI
    INC $0225
    INC count2
    LDA #$01
    STA game_over
    LDA #$02;
    STA $0211;
    LDA #$50
    STA $0210
    STA $0213


ContinueNMI:
    LDA direction_byte
    CMP #$00
    BEQ GoDownRight
    CMP #$01
    BNE Contt
    JMP GoUpRight
Contt:
    CMP #$10
    BNE Continue
    JMP GoUpLeft
Continue:
    CMP #$11
    BNE ll
    JMP GoDownLeft
ll:

GoDownRight:
    LDA ball_x
    CLC
    ADC ball_dx
    STA ball_x
    STA $0213

    LDA ball_y
    CLC
    ADC ball_dy
    STA ball_y
    STA $0210

    LDA ball_y
    CMP #$E5
    BCC ContinueCheckingDownRight

    LDA #$01
    STA direction_byte
    ;

    JMP LatchController 

ContinueCheckingDownRight:
    LDA ball_x
    CMP #$F0
    BNE CheckRightDownWithPlayer2
    LDA #$11
    STA direction_byte
    ;
    JMP LatchController
ToLatchController:
    JMP LatchController

CheckRightDownWithPlayer2:
    LDA #$D9
    CMP ball_x
    BCC ContinuePlayer22
    JMP LatchController
ContinuePlayer22:
    LDA $0214
    CMP ball_y
    BCC YContinue22
    JMP LatchController
YContinue22:
    LDA $0220
    CMP ball_y
    BCC ToLatchController
ChangeByteDownRight:
    LDA #$11
    STA direction_byte
    JSR PlaySound
    JMP LatchController 

GoUpRight:
    LDA ball_x
    CLC
    ADC ball_dx
    STA ball_x
    STA $0213

    LDA ball_y
    CLC
    SBC ball_dy
    STA ball_y
    STA $0210  

    LDA ball_y
    CMP #$08
    BCS ContinueCheckingUpRight

    LDA #$00
    STA direction_byte
    ;
    JMP LatchController 

ContinueCheckingUpRight:
    LDA ball_x
    CMP #$F0
    BNE CheckRightUpWithPlayer2
    ;BNE LatchController
    LDA #$10
    STA direction_byte
    ;
    ;JMP LatchController ??

CheckRightUpWithPlayer2:
    LDA #$D9
    CMP ball_x
    BCC ContinuePlayer2
    JMP LatchController
ContinuePlayer2:
    LDA $0214
    CMP ball_y
    BCC YContinue2
    JMP LatchController
YContinue2:
    LDA $0220
    CMP ball_y
    BCC ToLatchController
ChangeByteUpRight:
    LDA #$10
    STA direction_byte
    JSR PlaySound
    JMP LatchController    

GoDownLeft:
    LDA ball_x
    CLC
    SBC ball_dx
    STA ball_x
    STA $0213

    LDA ball_y
    CLC
    ADC ball_dy
    STA ball_y
    STA $0210

    LDA ball_y
    CMP #$E1
    BNE ContinueCheckingDownLeft

    LDA #$10
    STA direction_byte
    ;
    JMP LatchController      

ContinueCheckingDownLeft:
    LDA ball_x
    CMP #$02
    BCS CheckDownLeftWithPlayer1
    LDA #$00
    STA direction_byte
    ;
    JMP LatchController

CheckDownLeftWithPlayer1:
    LDA #$0E ;;;
    CMP ball_x
    BCC LatchController
    LDA $0200
    CMP ball_y
    BCC YContinue1
    JMP LatchController
YContinue1:
    LDA $020C
    CMP ball_y
    BCC LatchController
ChangeByteDownLeft:
    LDA #$00
    STA direction_byte
    JSR PlaySound
    JMP LatchController

GoUpLeft:
    LDA ball_x
    CLC
    SBC ball_dx
    STA ball_x
    STA $0213

    LDA ball_y
    CLC
    SBC ball_dy
    STA ball_y
    STA $0210

    LDA ball_y
    CMP #$02
    BCS ContinueCheckingUpLeft

    LDA #$11
    STA direction_byte
    ;
    JMP LatchController 

ContinueCheckingUpLeft:
    LDA ball_x
    CMP #$02
    BCS CheckUpLeftWithPlayer1
    LDA #$01
    STA direction_byte
    ;
    JMP LatchController

CheckUpLeftWithPlayer1:
    LDA #$0E
    CMP ball_x
    BCC LatchController
    LDA $0200
    CMP ball_y
    BCC YContinue
    JMP LatchController
YContinue:
    LDA $020C
    CMP ball_y
    BCC LatchController

ChangeByteUpLeft:
    LDA #$01
    STA direction_byte
    JSR PlaySound

LatchController:
    LDA #$01
    STA $4016
    LDA #$00
    STA $4016 

ReadA: 
    LDA $4016    
    AND #%00000001 
    BNE DoA
    JMP ReadADone

DoA:


ReadADone:        
  
ReadB: 
  LDA $4016      
  AND #%00000001  
  BEQ ReadBDone 

ReadBDone:       

ReadSelect: 
  LDA $4016      
  AND #%00000001  
  BEQ ReadSelectDone  

ReadSelectDone:

ReadStart: 
  LDA $4016      
  AND #%00000001  
  BEQ ReadStartDone 
  JMP DoStart

DoStart:
  LDA #$50
  STA ball_x
  STA ball_y
  LDA #$01
  STA direction_byte
  LDA #$00
  STA game_over
  LDA #$01
  STA $0211

ReadStartDone:


ReadUp: 
  LDA $4016      
  AND #%00000001 
  BNE DoUp
  JMP ReadUpDone 

DoUp:
    LDA $0200
    CMP #$02
    BCC ReadUpDone
    DEC $0200
    DEC $0200
    DEC $0204
    DEC $0204
    DEC $0208
    DEC $0208
    DEC $020C
    DEC $020C
ReadUpDone:

ReadDown: 
    LDA $4016      
    AND #%00000001 
    BNE DoDown
    JMP ReadDownDone 
DoDown:
    LDA $020C
    CMP #$E3
    BCS ReadDownDone
    INC $0200
    INC $0200
    INC $0204
    INC $0204
    INC $0208
    INC $0208
    INC $020C
    INC $020C

ReadDownDone:

ReadLeft: 
  LDA $4016      
  AND #%00000001 
  BNE DoLeft
  JMP ReadLeftDone 

DoLeft: 

ReadLeftDone:

ReadRight: 
  LDA $4016      
  AND #%00000001  
  BNE DoRight
  JMP ReadRightDone 

DoRight:

ReadRightDone:

LatchController2:
    LDA #$01
    STA $4017
    LDA #$00
    STA $4017 

ReadA2: 
    LDA $4017       
    AND #%00000001  
    BNE DoA2
    JMP ReadADone2

DoA2:


ReadADone2:        
  
ReadB2: 
  LDA $4017       
  AND #%00000001  
  BEQ ReadBDone2   
                  
ReadBDone2:        

ReadSelect2: 
  LDA $4017       
  AND #%00000001  
  BEQ ReadSelectDone2  

ReadSelectDone2:

ReadStart2: 
  LDA $4017       
  AND #%00000001 
  BEQ ReadStartDone2 
  JMP DoStart2

DoStart2:
  LDA #$50
  STA ball_x
  STA ball_y
  LDA #$01
  STA direction_byte
  LDA #$00
  STA game_over
  LDA #$01
  STA $0211

ReadStartDone2:


ReadUp2: 
  LDA $4017      
  AND #%00000001  
  BNE DoUp2
  JMP ReadUpDone2 
DoUp2:
    LDA $0214
    CMP #$02
    BCC ReadUpDone2
    DEC $0214
    DEC $0214
    DEC $0218
    DEC $0218
    DEC $021C
    DEC $021C
    DEC $0220
    DEC $0220
ReadUpDone2:

ReadDown2: 
    LDA $4017       
    AND #%00000001 
    BNE DoDown2
    JMP ReadDownDone2

DoDown2:
    LDA $0220
    CMP #$E3
    BCS ReadDownDone2
    INC $0214
    INC $0214
    INC $0218
    INC $0218
    INC $021C
    INC $021C
    INC $0220
    INC $0220

ReadDownDone2:

ReadLeft2: 
  LDA $4017       
  AND #%00000001
  BNE DoLeft2
  JMP ReadLeftDone2   ;

DoLeft2: 
  
ReadLeftDone2:

ReadRight2: 
  LDA $4017       
  AND #%00000001  
  BNE DoRight2
  JMP ReadRightDone2 

;Move to the right  
DoRight2:
  
ReadRightDone2:  

    LDA game_over
    CMP #$01
    BNE End
    JMP Foreverloop
GameOver:
    LDA #$50
    STA ball_x
    STA ball_y
    STA $0210
    STA $0213
    LDA #$01
    STA direction_byte
    LDA #$00
    STA game_over
    LDA #$01
    STA $0211
    LDA #$03
    STA $0225
    STA $0229 
    JMP Foreverloop 
End:

  RTI

;;; Setup palette

  .bank 1

  .org $E000
background_palette:
  .db $22, $29, $1A, $0F ;background palette 1
  .db $22, $36, $17, $0F ;background palette 2
  .db $22, $30, $21, $0F ;background palette 3
  .db $22, $27, $17, $0F ;background palette 4

sprite_palette:
  .db $FF, $16, $31, $20 ;sprite palette 1
  .db $22, $1A, $30, $27 ;sprite palette 2
  .db $22, $16, $30, $27 ;sprite palette 3
  .db $22, $0F, $36, $17   ;sprite palette 4

sprites:
    ;  Y   tile    attr     X
  .db $4A, $00, %00000000, $0C   ;sprite 0
  .db $52, $00, %00000000, $0C   ;sprite 1
  .db $5A, $00, %00000000, $0C   ;sprite 2
  .db $62, $00, %00000000, $0C   ;sprite 3 
ball:
  .db $50, $01, %00000000, $50   ; ball sprite
player_2:
  .db $4A, $00, %00000000, $E0
  .db $52, $00, %00000000, $E0 
  .db $5A, $00, %00000000, $E0 
  .db $62, $00, %00000000, $E0 
;0220
;0224
count1_sprite:
  .db $D0, $03, %00000000, $75
count2_sprite:
  .db $D0, $03, %00000000, $7F
dots:
  .db $D0, $25, %00000000, $7A

; ball Y = $0210
; ball X = $0213

;;; setup interrrupts

  .org $FFFA
  .dw NMI
  .dw RESET
  .dw 0

  .bank 2
  .org $0000
  .incbin "ttt.chr"