#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

jmp cstrt
nop

; IVT init
        dw  0000
        dw  0000
        dw  nmi_isr
        dw  0000
        db  1012 dup(0)
; IVT end

; data declaration start
seconds      db  00h
minutes      db  00h
hours        db  00h
day          db  00h
month        db  00h
year         db  00h
time_format  db  00h
alarm_hr     db  00h
alarm_min    db  00h
; data declaration end


cstrt:

; intialize ds, es,ss to start of RAM
mov ax, 0200h
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0FFFEH

; const declarations
LCDPORTA 	equ 00h
LCDPORTB 	equ 02h
LCDPORTC 	equ 04h
LCDPORTCWD 	equ 06h

CNTR0PORT   equ 08h
CNTR1PORT   equ 0Ah
CNTR2PORT   equ 0Ch
CNTRPORTCWD equ 0Eh

XTRPORTA    equ 10h
XTRPORTB    equ 12h
XTRPORTC    equ 14h
XTRPORTCWD  equ 16h

SETHR       equ 01h
SETMIN      equ 02h
SETSC       equ 04h
SETD        equ 08h
SETM        equ 10h
SETY        equ 20h
SETAHR      equ 40h
SETAMIN     equ 80h
; const declarations end
              
;; PPI INIT START
; initialize LCD's 8255 port A, C as output, B as input
mov al, 10000010b
out LCDPORTCWD, al

mov al, 10010010b
out XTRPORTCWD, al

mov al, 80h
out 1eh, al

; initialize 8253
;program timer  - both timer 0 and 1 in mode 2 - pulse generator        
mov al,00110100b
out CNTRPORTCWD, al 
mov al,01110100b 
out CNTRPORTCWD, al 
;timer 0 clk - 2 MHz and output is 100 KHz - count 20(14H)
mov al,0e8H
out CNTR0PORT, al
mov al,03h
out CNTR0PORT, al
;; PPI INIT END 


; set variables
mov seconds, 50h
mov minutes, 59h
mov hours, 23h
mov day, 01h
mov month, 02h
mov year, 00h
mov alarm_hr, 00h
mov alarm_min, 00h
mov time_format, 00h

 ; 0 => 24, 1 => 12

; lcd init start
mov bl, 38h
call lcd_cmd

mov bl, 38h
call lcd_cmd

mov bl, 0eh
call lcd_cmd

mov bl, 06h
call lcd_cmd
; lcd init end

mov bl, 0ch ; hides cursor
call lcd_cmd

call display

mov al, seconds
out LCDPORTB, al 

main:
    in al, XTRPORTA
    cmp al, 00
    je main
    
    cmp al, 00000001b
    jne mn1
    call set_hour
mn1:
    cmp al, 00000010b
    jne mn2
    call set_min
mn2:
	cmp al, 00000100b
    jne mn3
    call set_sec
mn3:
	cmp al, 00001000b
    jne mn4
    call set_day
mn4:
	cmp al, 00010000b
    jne mn5
    call set_month
mn5:
    cmp al, 00100000b
    jne mn6
    call set_year
mn6:
    cmp al, 01000000b
    jne mn7
    call set_alarm_hour
mn7:
	cmp al, 10000000b
    jne mn8
    call set_alarm_min
mn8:
jmp main

set_hour proc near
	mov bl, 01h
    call lcd_cmd
	call display
shrstart:
    ; first check if we are in set_hour or not
    in al, XTRPORTA
    cmp al, SETHR
    jne shrend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je shrx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_hour
    ; check if the inc, dec buttons are released
shrx1:
    in al, XTRPORTB
    cmp al, 00h
    jne shrx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je shrx2
    call display
  
shrx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETHR
    jne shrend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je shrx3
    call display
    
shrx3:
    in al, XTRPORTB 
    cmp al, 00h
    je shrx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne shrx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je shrx12
    call display
    
shrx12:
    in al, XTRPORTB
    cmp al, 01h
    jne shrdec

shrinc:
    mov dl, hours
    cmp dl, 23h
    jne shrx4
    ; 0 <= 23
    mov hours, 00h
    jmp shrdisp
    shrx4:
    mov dl, hours
    call bcd_add_one
    mov hours, dl
    jmp shrdisp
    
shrdec:
    mov dl, hours
    cmp dl, 00h
    jne shrx5
    ; 0 <= 23
    mov hours, 23h
    jmp shrdisp
    shrx5:
    mov dl, hours
    call bcd_sub_one
    mov hours, dl
    jmp shrdisp
    
shrdisp:
    call display
    jmp  shrstart
    
    
shrend:    
    ret
set_hour endp

set_min proc near
	mov bl, 01h
    call lcd_cmd
	call display
smnstart:
    ; first check if we are in set_min or not
    in al, XTRPORTA
    cmp al, SETMIN
    jne smnend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smnx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_min
    ; check if the inc, dec buttons are released
smnx1:
    in al, XTRPORTB
    cmp al, 00h
    jne smnx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smnx2
    call display
  
smnx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETMIN
    jne smnend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smnx3
    call display
    
smnx3:
    in al, XTRPORTB 
    cmp al, 00h
    je smnx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne smnx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smnx12
    call display
    
smnx12:
    in al, XTRPORTB
    cmp al, 01h
    jne smndec

smninc:
    mov dl, minutes
    cmp dl, 59h
    jne smnx4
    ; 0 <= 59
    mov minutes, 00h
    jmp smndisp
    smnx4:
    mov dl, minutes
    call bcd_add_one
    mov minutes, dl
    jmp smndisp
    
smndec:
    mov dl, minutes
    cmp dl, 00h
    jne smnx5
    ; 59 <= 0
    mov minutes, 59h
    jmp smndisp
    smnx5:
    mov dl, minutes
    call bcd_sub_one
    mov minutes, dl
    jmp smndisp
    
smndisp:
    call display
    jmp  smnstart
    
    
smnend:    
    ret
set_min endp

set_sec proc near
	mov bl, 01h
    call lcd_cmd
	call display
sscstart:
    ; first check if we are in set_sec or not
    in al, XTRPORTA
    cmp al, SETSC
    jne sscend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sscx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_sec
    ; check if the inc, dec buttons are released
sscx1:
    in al, XTRPORTB
    cmp al, 00h
    jne sscx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sscx2
    call display
  
sscx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETSC
    jne sscend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sscx3
    call display
    
sscx3:
    in al, XTRPORTB 
    cmp al, 00h
    je sscx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne sscx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sscx12
    call display
    
sscx12:
    in al, XTRPORTB
    cmp al, 01h
    jne sscdec

sscinc:
    mov dl, seconds
    cmp dl, 59h
    jne sscx4
    ; 0 <= 59
    mov seconds, 00h
    jmp sscdisp
    sscx4:
    mov dl, seconds
    call bcd_add_one
    mov seconds, dl
    jmp sscdisp
    
sscdec:
    mov dl, seconds
    cmp dl, 00h
    jne sscx5
    ; 59 <= 0
    mov seconds, 59h
    jmp sscdisp
    sscx5:
    mov dl, seconds
    call bcd_sub_one
    mov seconds, dl
    jmp sscdisp
    
sscdisp:
    call display
    jmp  sscstart
    
    
sscend:    
    ret
set_sec endp

set_day proc near
	mov bl, 01h
    call lcd_cmd
	call display
sdystart:
    call get_month_max
    mov cl, al
    ; first check if we are in set_day or not
    in al, XTRPORTA
    cmp al, SETD
    jne sdyend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sdyx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_day
    ; check if the inc, dec buttons are released
sdyx1:
    in al, XTRPORTB
    cmp al, 00h
    jne sdyx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sdyx2
    call display
  
sdyx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETD
    jne sdyend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sdyx3
    call display
    
sdyx3:
    in al, XTRPORTB 
    cmp al, 00h
    je sdyx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne sdyx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sdyx12
    call display
    
sdyx12:
    in al, XTRPORTB
    cmp al, 01h
    jne sdydec

sdyinc:
    mov dl, day
    cmp dl, cl
    jne sdyx4
    ; 0 <= 59
    mov day, 01h
    jmp sdydisp
    sdyx4:
    mov dl, day
    call bcd_add_one
    mov day, dl
    jmp sdydisp
    
sdydec:
    mov dl, day
    cmp dl, 01h
    jne sdyx5
    ; 59 <= 0
    mov day, cl
    jmp sdydisp
    sdyx5:
    mov dl, day
    call bcd_sub_one
    mov day, dl
    jmp sdydisp
    
sdydisp:
    call display
    jmp  sdystart
    
    
sdyend:    
    ret
set_day endp

set_month proc near
	mov bl, 01h
    call lcd_cmd
	call display
smtstart:
    ; first check if we are in set_month or not
    in al, XTRPORTA
    cmp al, SETM
    jne smtend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smtx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_month
    ; check if the inc, dec buttons are released
smtx1:
    in al, XTRPORTB
    cmp al, 00h
    jne smtx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smtx2
    call display
  
smtx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETM
    jne smtend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smtx3
    call display
    
smtx3:
    in al, XTRPORTB 
    cmp al, 00h
    je smtx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne smtx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je smtx12
    call display
    
smtx12:
    in al, XTRPORTB
    cmp al, 01h
    jne smtdec

smtinc:
    mov dl, month
    cmp dl, 12h
    jne smtx4
    ; 0 <= 59
    mov month, 01h
    jmp smtdisp
    smtx4:
    mov dl, month
    call bcd_add_one
    mov month, dl
    jmp smtdisp
    
smtdec:
    mov dl, month
    cmp dl, 12h
    jne smtx5
    ; 59 <= 0
    mov month, 12h
    jmp smtdisp
    smtx5:
    mov dl, month
    call bcd_sub_one
    mov month, dl
    jmp smtdisp
    
smtdisp:
    mov day, 01h
    call display
    jmp  smtstart
    
    
smtend:    
    ret
set_month endp

set_year proc near
	mov bl, 01h
    call lcd_cmd
	call display
syrstart:
    ; first check if we are in set_year or not
    in al, XTRPORTA
    cmp al, SETY
    jne syrend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je syrx1
    call display
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_year
    ; check if the inc, dec buttons are released
syrx1:
    in al, XTRPORTB
    cmp al, 00h
    jne syrx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je syrx2
    call display
  
syrx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETY
    jne syrend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je syrx3
    call display
    
syrx3:
    in al, XTRPORTB 
    cmp al, 00h
    je syrx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne syrx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je syrx12
    call display
    
syrx12:
    in al, XTRPORTB
    cmp al, 01h
    jne syrdec

syrinc:
    mov dl, year
    cmp dl, 99h
    jne syrx4
    ; 0 <= 59
    mov year, 00h
    jmp syrdisp
    syrx4:
    mov dl, year
    call bcd_add_one
    mov year, dl
    jmp syrdisp
    
syrdec:
    mov dl, year
    cmp dl, 00h
    jne syrx5
    ; 59 <= 0
    mov year, 99h
    jmp syrdisp
    syrx5:
    mov dl, year
    call bcd_sub_one
    mov year, dl
    jmp syrdisp
    
syrdisp:
    mov day, 01h
    call display
    jmp  syrstart
    
    
syrend:    
    ret
set_year endp

set_alarm_hour proc near
	mov bl, 01h
    call lcd_cmd
	call display_alarm
samstart:
    ; first check if we are in set_alarm_hour or not
    in al, XTRPORTA
    cmp al, SETAHR
    jne samend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je samx1
    call display_alarm
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_alarm_hour
    ; check if the inc, dec buttons are released
samx1:
    in al, XTRPORTB
    cmp al, 00h
    jne samx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je samx2
    call display_alarm
  
samx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETAHR
    jne samend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je samx3
    call display_alarm
    
samx3:
    in al, XTRPORTB 
    cmp al, 00h
    je samx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne samx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je samx12
    call display_alarm
    
samx12:
    in al, XTRPORTB
    cmp al, 01h
    jne samdec

saminc:
    mov dl, alarm_hr
    cmp dl, 23h
    jne samx4
    ; 0 <= 23
    mov alarm_hr, 00h
    jmp samdisp
    samx4:
    mov dl, alarm_hr
    call bcd_add_one
    mov alarm_hr, dl
    jmp samdisp
    
samdec:
    mov dl, alarm_hr
    cmp dl, 00h
    jne samx5
    ; 0 <= 23
    mov alarm_hr, 23h
    jmp samdisp
    samx5:
    mov dl, alarm_hr
    call bcd_sub_one
    mov alarm_hr, dl
    jmp samdisp
    
samdisp:
    call display_alarm
    jmp  samstart
    
    
samend:    
    ret
set_alarm_hour endp

set_alarm_min proc near
	mov bl, 01h
    call lcd_cmd
	call display_alarm
sahstart:
    ; first check if we are in set_alarm_min or not
    in al, XTRPORTA
    cmp al, SETAMIN
    jne sahend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sahx1
    call display_alarm
    
    mov al, 69h
	out 18h, al
    
    ; now we are for sure in set_alarm_min
    ; check if the inc, dec buttons are released
sahx1:
    in al, XTRPORTB
    cmp al, 00h
    jne sahx1
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sahx2
    call display_alarm
  
sahx2:
    ; sanity check
    in al, XTRPORTA
    cmp al, SETAMIN
    jne sahend
    
    ; now inc, dec buttons arent held down
    ; check if we need refresh the lcd screen
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sahx3
    call display_alarm
    
sahx3:
    in al, XTRPORTB 
    cmp al, 00h
    je sahx2
    mov bl, al
    call delay_20ms
    in al, XTRPORTB
    cmp al, bl
    jne sahx2
    
    ; now we know button is being held
    ; check if increment or  decrement
    
    in al, LCDPORTB
    and al, 01h
    mov bl, time_format
	cmp al, bl
    je sahx12
    call display_alarm
    
sahx12:
    in al, XTRPORTB
    cmp al, 01h
    jne sahdec

sahinc:
    mov dl, alarm_min
    cmp dl, 59h
    jne sahx4
    ; 0 <= 59
    mov alarm_min, 00h
    jmp sahdisp
    sahx4:
    mov dl, alarm_min
    call bcd_add_one
    mov alarm_min, dl
    jmp sahdisp
    
sahdec:
    mov dl, alarm_min
    cmp dl, 00h
    jne sahx5
    ; 59 <= 0
    mov alarm_min, 59h
    jmp sahdisp
    sahx5:
    mov dl, alarm_min
    call bcd_sub_one
    mov alarm_min, dl
    jmp sahdisp
    
sahdisp:
    call display_alarm
    jmp  sahstart
    
    
sahend:    
    ret
set_alarm_min endp


lcd_cmd proc near
	mov al, bl
	out 00h,al 
	
	mov al,00000100b
	out LCDPORTC,al
	call lcdDelay
	
	mov al,00000000b
	out LCDPORTC,al
	call lcdDelay
	;call delay_20ms
	
	ret
lcd_cmd endp

write_char proc near
	mov al, bl
	out LCDPORTA, al

	mov al,00000101b
	out LCDPORTC,al
	call lcdDelay
	
	mov al,00000001b
	out LCDPORTC,al
	call lcdDelay
	;call delay_20ms
	
	ret
write_char endp
	
lcd_line_1 proc near
    mov bl, 80h
    call lcd_cmd
    ret       
lcd_line_1 endp
    
lcd_line_2 proc near
    mov bl, 0c0h
    call lcd_cmd
    ret             
lcd_line_2 endp

lcdDelay proc near     
	mov cx, 100
	xn:
		loop xn
	ret
lcdDelay endp         
; 01h -> 00H
; RS-E -> RS-E

bcd_add_one proc near
    mov al, dl
	mov bl, 1
	add al, bl
	daa
	mov dl, al

	ret               
bcd_add_one endp

bcd_sub_one proc near
    mov al, dl
	mov bl, 1
	sub al, bl
	das
	mov dl, al

	ret               
bcd_sub_one endp

display_number proc near
    ; input  - number in dl
    ; output - number displayed in LCD screen
    mov bl, 0f0h
    mov cl, 4
    and bl, dl
    ror bl, cl
    add bl, '0'
    call write_char
    
    mov bl, 0fh
    and bl, dl
    add bl, '0'
    call write_char
	
	ret                    
display_number endp
	
get_month_max proc near
    mov dl, month
    cmp dl, 01h
    jne gfeb
    mov al, 31h
    jmp gend
gfeb:
    cmp dl, 02h
    jne gmarch
	mov al, 28h
    jmp gend   
gmarch:
    cmp dl, 03h
    jne gapril
    mov al, 31h
    jmp gend
gapril:
    cmp dl, 04h
    jne gmay
    mov al, 30h
    jmp gend
gmay:
    cmp dl, 05h
    jne gjune
    mov al, 31h
    jmp gend
gjune:
    cmp dl, 06h
    jne gjuly
    mov al, 30h
    jmp gend
gjuly:
    cmp dl, 07h
    jne gaugust
    mov al, 31h
    jmp gend
gaugust:
    cmp dl, 08h
    jne gsept
    mov al, 31h
    jmp gend
gsept:
    cmp dl, 09h
    jne goct
    mov al, 30h
    jmp gend
goct:
    cmp dl, 10h
    jne gnov
    mov al, 31h
    jmp gend
gnov:
    cmp dl, 11h
    jne gdec
    mov al, 30h
    jmp gend
gdec:    
    mov al, 31h
    jmp gend
gend:   
    ret
get_month_max endp

leap_year proc near
	lea si, year
	mov bl, [si]
	and bl, 0fh
	mov al, [si]
	and al, 0f0h
	mov cl, 04d
	ror al, cl
	mov dl, 0ah
	mul dl
	add al, bl
	
	and al, 00000011b
	cmp al, 0
	jne lno
lyes:
	; is leap year, move 29h to al
	mov al, 29h
	jmp lend
lno:
	mov al, 28h
	jmp lend
lend:
leap_year endp 
   

nmi_isr:
    mov dl, seconds
    call bcd_add_one
    mov seconds, dl
    cmp dl, 60h
    jne ndisplay
    
; update minutes
    mov seconds, 00h
    mov dl, minutes
    call bcd_add_one
    mov minutes, dl
    cmp dl, 60h
    jne ndisplay
    
; update hours
    mov minutes, 00h
    mov dl, hours
    call bcd_add_one
    mov hours, dl
    cmp dl, 24h
    jne ndisplay

; update day
    mov hours, 00h
    mov dl, day
    call bcd_add_one
    mov day, dl
    call get_month_max
    mov dl, al
    call bcd_add_one
    mov al, dl
    mov dl, day
    cmp dl, al
    jne ndisplay
    
; update month
    mov day, 01h
    mov dl, month
    call bcd_add_one
    mov month, dl
    cmp month, 13h
    jne ndisplay

; update year
    mov month, 01h
    mov dl, year
    call bcd_add_one
    mov year, dl
    
ndisplay:       

; alarm
    mov al, hours
    mov bl, alarm_hr
    cmp al, bl
    jne nskip
    mov al, minutes
    mov bl, alarm_min
    cmp al, bl
    jne nskip
    mov al, 01h
    out XTRPORTC, al
    jmp nndisplay
nskip:
    mov al, 00h
    out XTRPORTC, al
    jmp nndisplay

nndisplay:
    mov cl, 01h
    call display
    iret    
    
    
; display time
display proc near
    ;mov bl, 01h
    ;call lcd_cmd
       
    call lcd_line_1
    
    in al, LCDPORTB
    ; al = 0 -> 24, al = 1 -> 12
    and al, 00000001b   
    cmp al, 01h
    je ndisplay_12
     
    ; display 24 hour time_format
    cmp al, time_format
	je ndisx24
	mov bl, 01h
	call lcd_cmd
	call lcd_line_1
	mov time_format, 00h
	ndisx24:
	
    mov dl, hours
	call display_number
	
	mov bl, ':'
	call write_char
	
	mov dl, minutes
	call display_number
	
	mov bl, ':'
	call write_char
	
	mov dl, seconds
	call display_number
	

	
	jmp ndisplay_date

ndisplay_12:	
	; display 12 hour time_format
	in al, LCDPORTB
    ; al = 0 -> 24, al = 1 -> 12
    and al, 00000001b
	cmp al, time_format
	je ndisx12
	mov bl, 01h
	call lcd_cmd
	call lcd_line_1
	mov time_format, 01h
	ndisx12:
	
	
	mov dl, hours
	cmp dl, 12h
	ja n_pm
	; display as am
	mov dl, hours
	cmp dl, 00h
	jne nx1
	mov dl, 12h
    call display_number
    jmp nx2
nx1:
    mov dl, hours
    call display_number
nx2:	
	mov bl, ':'
	call write_char
	
	mov dl, minutes
	call display_number
	
	mov bl, ':'
	call write_char
	
	mov dl, seconds
	call display_number
	
	mov bl, 'A'
	call write_char
	
	mov bl, 'M'
	call write_char
	
    jmp ndisplay_date
    
n_pm:
    mov al, hours
    sub al, 12h
    das
    
    mov dl, al
    call display_number 
        
	mov bl, ':'
	call write_char
	
	mov dl, minutes
	call display_number
	
	mov bl, ':'
	call write_char
	
	mov dl, seconds
	call display_number
	
	mov bl, 'P'
	call write_char
	
	mov bl, 'M'
	call write_char
	
	
ndisplay_date:	
	call lcd_line_2

	mov dl, day
	call display_number
	
	mov bl, '/'
	call write_char
	
	mov dl, month
	call display_number
	
	mov bl, '/'
	call write_char
	
	mov dl, year
	call display_number
	
	mov bl, 80h
	call lcd_cmd
	
    ret
display endp

display_alarm proc near
    call lcd_line_1
    
    mov bl, 'A'
	call write_char
	
	mov bl, 'L'
	call write_char
	
	mov bl, 'A'
	call write_char
	
	mov bl, 'R'
	call write_char
	
	mov bl, 'M'
	call write_char
	
	mov bl, ':'
	call write_char
	
	call lcd_line_2
	
	in al, LCDPORTB
    ; al = 0 -> 24, al = 1 -> 12
    and al, 00000001b   
    cmp al, 01h
    je nadisplay_12
     
    ; display 24 hour time_format
    cmp al, time_format
	je nadisx24
	mov bl, 01h
	call lcd_cmd
	call lcd_line_1
	mov time_format, 00h
	nadisx24:
	
    mov dl, alarm_hr
	call display_number
	
	mov bl, ':'
	call write_char
	
	mov dl, alarm_min
	call display_number
	
	jmp naend

nadisplay_12:	
	; display 12 hour time_format
	in al, LCDPORTB
    ; al = 0 -> 24, al = 1 -> 12
    and al, 00000001b
	cmp al, time_format
	je nadisx12
	mov bl, 01h
	call lcd_cmd
	call lcd_line_1
	mov time_format, 01h
	nadisx12:
	
	
	mov dl, alarm_hr
	cmp dl, 12h
	ja na_pm
	; display as am
	mov dl, alarm_hr
	cmp dl, 00h
	jne nax1
	mov dl, 12h
    call display_number
    jmp nax2
nax1:
    mov dl, alarm_hr
    call display_number
nax2:	
	mov bl, ':'
	call write_char
	
	mov dl, alarm_min
	call display_number
	
	mov bl, 'A'
	call write_char
	
	mov bl, 'M'
	call write_char
	
    jmp naend
	
na_pm:
    mov al, alarm_hr
    sub al, 12h
    das
    
    mov dl, al
    call display_number 
        
	mov bl, ':'
	call write_char
	
	mov dl, alarm_min
	call display_number
	
	mov bl, 'P'
	call write_char
	
	mov bl, 'M'
	call write_char
	
naend:

	mov bl, 80h
	call lcd_cmd
	
	ret   
display_alarm endp
    
delay_20ms proc near
    push 	cx
	mov 	cx,900d		
dl1:
    nop							
	loop 	dl1					
				
	pop 	cx					
	ret
delay_20ms endp 