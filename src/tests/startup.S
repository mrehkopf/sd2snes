/* startup code for LPC17xx
 *
 * Written 2010 by Ingo Korb
 */
        .syntax unified

        .section .vectors

        .macro  except label
        .weak   \label
        .set    \label, __unhandled_exception
        .word   \label
        .endm
        
        /* Cortex M3 standard except vectors */
        .word   __stack
        .word   _start
        except  NMI_Handler
        except  HardFault_Handler
        except  MemManage_Handler
        except  BusFault_Handler
        except  UsageFault_Handler
        .word   0
        .word   0
        .word   0
        .word   0
        except  SVC_Handler
        except  DebugMon_Handler
        .word   0
        except  PendSV_Handler
        except  SysTick_Handler

        /* External interrupt vectors */
        except  WDT_IRQHandler
        except  TIMER0_IRQHandler
        except  TIMER1_IRQHandler
        except  TIMER2_IRQHandler
        except  TIMER3_IRQHandler
        except  UART0_IRQHandler
        except  UART1_IRQHandler
        except  UART2_IRQHandler
        except  UART3_IRQHandler
        except  PWM1_IRQHandler
        except  I2C0_IRQHandler
        except  I2C1_IRQHandler
        except  I2C2_IRQHandler
        except  SPI_IRQHandler
        except  SSP0_IRQHandler
        except  SSP1_IRQHandler
        except  PLL0_IRQHandler
        except  RTC_IRQHandler
        except  EINT0_IRQHandler
        except  EINT1_IRQHandler
        except  EINT2_IRQHandler
        except  EINT3_IRQHandler
        except  ADC_IRQHandler
        except  BOD_IRQHandler
        except  USB_IRQHandler
        except  CAN_IRQHandler
        except  DMA_IRQHandler
        except  I2S_IRQHandler
        except  ENET_IRQHandler
        except  RIT_IRQHandler
        except  MCPWM_IRQHandler
        except  QEI_IRQHandler
        except  PLL1_IRQHandler

        .section .text

        .global _start
        .thumb_func
_start:
        /* copy data section to ram */
        ldr     r0, =__data_load_start
        ldr     r1, =__data_load_end
        ldr     r2, =__data_start
dataloop:
        ldr.w   r3, [r0], #4
        str.w   r3, [r2], #4
        cmp     r0, r1
        blo     dataloop

        /* clear bss section */
        ldr     r0, =__bss_start__
        ldr     r1, =__bss_end__
        ldr     r2, =0
bssloop:
        str.w   r2, [r0], #4
        cmp     r0, r1
        blo     bssloop

        /* start main() */
        b       main

        /* endless loop */
        .weak __unhandled_exception
        .thumb_func
__unhandled_exception:
        b       __unhandled_exception
        
        .end
