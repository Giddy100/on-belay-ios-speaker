---
name: Belay is On Design System
colors:
  surface: '#1e100b'
  surface-dim: '#1e100b'
  surface-bright: '#47352f'
  surface-container-lowest: '#180b07'
  surface-container-low: '#271813'
  surface-container: '#2b1c17'
  surface-container-high: '#372621'
  surface-container-highest: '#42312b'
  on-surface: '#f9dcd4'
  on-surface-variant: '#e3bfb3'
  inverse-surface: '#f9dcd4'
  inverse-on-surface: '#3d2c27'
  outline: '#aa897f'
  outline-variant: '#A6B37D'
  surface-tint: '#ffb59c'
  primary: '#ffb59c'
  on-primary: '#5c1900'
  primary-container: '#ff5f1f'
  on-primary-container: '#561700'
  inverse-primary: '#ab3600'
  secondary: '#bec8cd'
  on-secondary: '#283236'
  secondary-container: '#414b4f'
  on-secondary-container: '#b0babf'
  tertiary: '#8dcdff'
  on-tertiary: '#00344f'
  tertiary-container: '#009de4'
  on-tertiary-container: '#00304a'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbcf'
  primary-fixed-dim: '#ffb59c'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#832700'
  secondary-fixed: '#dae4e9'
  secondary-fixed-dim: '#bec8cd'
  on-secondary-fixed: '#141d21'
  on-secondary-fixed-variant: '#3f484c'
  tertiary-fixed: '#cae6ff'
  tertiary-fixed-dim: '#8dcdff'
  on-tertiary-fixed: '#001e30'
  on-tertiary-fixed-variant: '#004b70'
  background: '#1e100b'
  on-background: '#f9dcd4'
  surface-variant: '#42312b'
  safety-orange: '#FF5F1F'
  chalk-white: '#F4F4F9'
  granite-gray: '#1A1C1E'
  slate-surface: '#2D3135'
  active-green: '#39FF14'
  warning-yellow: '#FFD700'
typography:
  headline-lg:
    fontFamily: Lexend
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Lexend
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Lexend
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-sm:
    fontFamily: Lexend
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
  status-code:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  margin-mobile: 20px
  gutter: 16px
  touch-target: 48px
  container-padding: 24px
---

# DESIGN.md

## Overview

This is a mobile application names "Belay is On" designed for climbers communication. 2 climbers will use the app and it will act like hand-free walkie talkie between them.
The communication will start with a wake-up word "Hey Moses" and then will follow with a climbing command such as "On Belay", "Climbing". Once one climber will say this command, the other climber will hear it.
The 2 climbers need to be on the same group. Therefore, part of the UI is creating, joining, selecting and activating a group.

## Screens
# Main Screen:
When launching the app, we will check if we already logged in and if yes, we will reach the "Main Screen". Here is the functionality needed in the "Main Screen".
Need to show the current logged in user name. 
Need ability to Create/Modify/View a group
Need the ability to join a group
Need the ability toset the current group from the groups the user is part of.
Once we have a current group, we should activate it which means we are listening to the other climber or we can say something and the other climber will hear us.
We need the ability to see messages coming from the speech analyzer 
We need the ability to set global values such as "User Name", "Volume"
Wew needs the ability to switch user

# Group Component:
- "Name". We will refer this field as "Create Group Name Edit Field".
- "Code". We will refer to it as "Create Group Code Edit Field". It should be exactly 4 digits.
- Start and End date - ability to choose a range when to start and end. We will refer it as "Create Group dates range. When entering, the start date will be today and the end date will be today + 7 days. You can't choose a range longer than 30 days.
- Phrases - Ability to see all the phrases and selectd/de select one of them

# To Join a Group:
We will search by name and the result will be displayed for the user. The user will select the matched group and click "Join". It will then need to match the 4 digits code of the group.

