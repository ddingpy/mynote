---
title: "Full MUI AppShell (React 19 + MUI v7): Complete Example"
date: 2026-01-19 23:18:00 +0900
excerpt: "Build a production-grade MUI AppShell with responsive navigation, routing, and modern theme switching."
tags: [react, mui, frontend, appshell]
---

{% raw %}

This document walks you from **zero → running app** with a production-grade **AppShell**:

* **Fixed AppBar** (top)
* **Responsive Drawer navigation**

  * `temporary` Drawer on small screens (hamburger menu)
  * `permanent` Drawer on desktop
* **Route-based content area** (React Router)
* **Light/Dark/System theme toggle** using MUI’s **latest color scheme system**
* Sensible defaults for spacing, accessibility, and layout stability

MUI’s most recent **stable** version is **v7.3.7** at the time of writing. ([MUI][1])
React’s current major line is **React 19** (latest documented minor is 19.2). ([ja.react.dev][2])
React Router’s current line is **v7** and is designed as a non-breaking upgrade path from v6. ([reactrouter.com][3])

---

## Table of contents

1. [Project setup (Vite + TypeScript)](#project-setup-vite--typescript)
2. [Install MUI (latest) + icons + router](#install-mui-latest--icons--router)
3. [Theme setup (latest: `colorSchemes` + `cssVariables`)](#theme-setup-latest-colorschemes--cssvariables)
4. [App entry point (`ThemeProvider` + `CssBaseline` + Router)](#app-entry-point-themeprovider--cssbaseline--router)
5. [Build the AppShell (AppBar + Responsive Drawer)](#build-the-appshell-appbar--responsive-drawer)
6. [Pages + routing (`Outlet`)](#pages--routing-outlet)
7. [Run it](#run-it)
8. [Optional upgrades (mini drawer, SSR/Next.js, Grid v2 notes)](#optional-upgrades-mini-drawer-ssrnextjs-grid-v2-notes)

---

## Project setup (Vite + TypeScript)

Create a new React + TS app using Vite:

```bash
npm create vite@latest mui-appshell -- --template react-ts
cd mui-appshell
npm install
```

> If you already have a project, you can skip this and only follow the installation + code sections.

---

## Install MUI (latest) + icons + router

### Install MUI core (Material UI + Emotion)

MUI’s default installation uses **Emotion** and the recommended install is: ([MUI][4])

```bash
npm install @mui/material @emotion/react @emotion/styled
```

### Install MUI icons

```bash
npm install @mui/icons-material
```

MUI’s docs call out installing icons separately. ([MUI][4])

### Install React Router

```bash
npm install react-router-dom
```

React Router’s current line is v7, and upgrading from v6 is intended to be non-breaking. ([reactrouter.com][3])

### Optional: Roboto (MUI default typography)

MUI uses Roboto by default; you can add it via Fontsource. ([MUI][4])

```bash
npm install @fontsource/roboto
```

---

## Theme setup (latest: `colorSchemes` + `cssVariables`)

MUI v7’s modern approach is:

* Use `colorSchemes` (recommended over the older `palette.mode` approach for richer built-in behavior) ([MUI][5])
* Enable CSS variables with `cssVariables` to support robust, flicker-resistant theming and advanced configuration ([MUI][6])
* Use `useColorScheme()` to toggle mode (light/dark/system) ([MUI][5])

### Create `src/theme.ts`

```ts
// src/theme.ts
import { createTheme } from '@mui/material/styles';

export const theme = createTheme({
  /**
   * Enable CSS theme variables (MUI v7).
   * - This unlocks robust color-scheme switching and better theming ergonomics.
   */
  cssVariables: {
    /**
     * Use a class on <html> to control the active scheme.
     * MUI will apply `.light` / `.dark` (or equivalent) to the root element.
     */
    colorSchemeSelector: 'class',
  },

  /**
   * Enable built-in schemes and customize them if you want.
   * If you only want the default schemes, you can use:
   *   colorSchemes: { light: true, dark: true }
   */
  colorSchemes: {
    light: {
      palette: {
        primary: { main: '#1976d2' },
        secondary: { main: '#9c27b0' },
      },
    },
    dark: {
      palette: {
        primary: { main: '#90caf9' },
        secondary: { main: '#ce93d8' },
      },
    },
  },

  typography: {
    fontFamily: [
      'Roboto',
      'system-ui',
      '-apple-system',
      'Segoe UI',
      'Helvetica',
      'Arial',
      'sans-serif',
    ].join(','),
  },

  shape: { borderRadius: 10 },
});
```

This uses MUI’s documented `cssVariables` + `colorSchemes` configuration patterns. ([MUI][6])

---

## App entry point (`ThemeProvider` + `CssBaseline` + Router)

### Why these choices

* `<CssBaseline />` provides a consistent baseline and can enable native `color-scheme` behavior via `enableColorScheme`. ([MUI][7])
* When using `colorSchemes`, `ThemeProvider` supports:

  * `defaultMode` (defaults to `system` when `colorSchemes` is provided) ([MUI][5])
  * `disableTransitionOnChange` for instant switching ([MUI][5])
  * `noSsr` is recommended for **client-only SPAs** to avoid extra rerenders and reduce flicker on refresh ([MUI][5])

### Update `src/main.tsx`

```tsx
// src/main.tsx
import React from 'react';
import ReactDOM from 'react-dom/client';

import CssBaseline from '@mui/material/CssBaseline';
import { ThemeProvider } from '@mui/material/styles';

import { BrowserRouter } from 'react-router-dom';

import App from './App';
import { theme } from './theme';

// Optional if you installed it:
// import '@fontsource/roboto/300.css';
// import '@fontsource/roboto/400.css';
// import '@fontsource/roboto/500.css';
// import '@fontsource/roboto/700.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ThemeProvider
      theme={theme}
      defaultMode="system"
      disableTransitionOnChange
      noSsr
    >
      <CssBaseline enableColorScheme />
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </ThemeProvider>
  </React.StrictMode>,
);
```

---

## Build the AppShell (AppBar + Responsive Drawer)

We’ll implement the “classic productivity shell”:

* **Fixed AppBar**
* **Drawer navigation** clipped under the AppBar
* **Main content** with an offset (so content isn’t hidden under the fixed AppBar)

MUI explicitly notes that a fixed AppBar can hide content and suggests adding an extra `<Toolbar />` (or using `theme.mixins.toolbar`) as an offset. ([MUI][8])

MUI’s Drawer docs also describe the **responsive pattern**: use `temporary` for small screens and `permanent` for wider screens. ([MUI][9])

### Create `src/layout/navItems.tsx`

```tsx
// src/layout/navItems.tsx
import DashboardIcon from '@mui/icons-material/Dashboard';
import AssessmentIcon from '@mui/icons-material/Assessment';
import SettingsIcon from '@mui/icons-material/Settings';

export type NavItem = {
  label: string;
  to: string;
  icon: React.ReactNode;
};

export const navItems: NavItem[] = [
  { label: 'Dashboard', to: '/dashboard', icon: <DashboardIcon /> },
  { label: 'Reports', to: '/reports', icon: <AssessmentIcon /> },
  { label: 'Settings', to: '/settings', icon: <SettingsIcon /> },
];
```

### Create `src/components/ModeToggle.tsx`

This uses the latest `useColorScheme` approach. MUI warns that `mode` is **undefined on first render**, so we guard for that. ([MUI][5])

```tsx
// src/components/ModeToggle.tsx
import * as React from 'react';
import IconButton from '@mui/material/IconButton';
import Tooltip from '@mui/material/Tooltip';

import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import SettingsBrightnessIcon from '@mui/icons-material/SettingsBrightness';

import { useColorScheme } from '@mui/material/styles';

type Mode = 'light' | 'dark' | 'system';

export function ModeToggle() {
  const { mode, setMode, systemMode } = useColorScheme();

  // Important: mode can be undefined on first render (SSR/hydration safety).
  if (!mode) return null;

  const effectiveMode = mode === 'system' ? systemMode : mode;

  const nextMode: Mode =
    mode === 'system' ? 'light' : mode === 'light' ? 'dark' : 'system';

  const icon =
    mode === 'system' ? (
      <SettingsBrightnessIcon />
    ) : effectiveMode === 'dark' ? (
      <DarkModeIcon />
    ) : (
      <LightModeIcon />
    );

  return (
    <Tooltip title={`Theme: ${mode} (click → ${nextMode})`}>
      <IconButton
        color="inherit"
        onClick={() => setMode(nextMode)}
        aria-label="Toggle color mode"
      >
        {icon}
      </IconButton>
    </Tooltip>
  );
}
```

### Create `src/components/UserMenu.tsx`

```tsx
// src/components/UserMenu.tsx
import * as React from 'react';
import Avatar from '@mui/material/Avatar';
import IconButton from '@mui/material/IconButton';
import Menu from '@mui/material/Menu';
import MenuItem from '@mui/material/MenuItem';
import Tooltip from '@mui/material/Tooltip';
import ListItemIcon from '@mui/material/ListItemIcon';

import LogoutIcon from '@mui/icons-material/Logout';
import PersonIcon from '@mui/icons-material/Person';

export function UserMenu() {
  const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };
  const handleClose = () => setAnchorEl(null);

  return (
    <>
      <Tooltip title="Account">
        <IconButton onClick={handleOpen} size="small" sx={{ ml: 1 }}>
          <Avatar sx={{ width: 32, height: 32 }}>U</Avatar>
        </IconButton>
      </Tooltip>

      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        onClick={handleClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <MenuItem>
          <ListItemIcon>
            <PersonIcon fontSize="small" />
          </ListItemIcon>
          Profile
        </MenuItem>
        <MenuItem>
          <ListItemIcon>
            <LogoutIcon fontSize="small" />
          </ListItemIcon>
          Logout
        </MenuItem>
      </Menu>
    </>
  );
}
```

### Create `src/layout/AppShell.tsx`

```tsx
// src/layout/AppShell.tsx
import * as React from 'react';

import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Divider from '@mui/material/Divider';
import Drawer from '@mui/material/Drawer';
import IconButton from '@mui/material/IconButton';
import List from '@mui/material/List';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemIcon from '@mui/material/ListItemIcon';
import ListItemText from '@mui/material/ListItemText';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';

import MenuIcon from '@mui/icons-material/Menu';

import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useTheme } from '@mui/material/styles';
import useMediaQuery from '@mui/material/useMediaQuery';

import { navItems } from './navItems';
import { ModeToggle } from '../components/ModeToggle';
import { UserMenu } from '../components/UserMenu';

const drawerWidth = 280;

export function AppShell() {
  const theme = useTheme();
  const isDesktop = useMediaQuery(theme.breakpoints.up('md'));
  const location = useLocation();

  const [mobileOpen, setMobileOpen] = React.useState(false);

  const handleDrawerToggle = () => setMobileOpen((prev) => !prev);

  // If we switch to desktop, ensure the temporary drawer is closed
  React.useEffect(() => {
    if (isDesktop) setMobileOpen(false);
  }, [isDesktop]);

  const drawerContent = (
    <Box>
      {/* Spacer so drawer content starts below the fixed AppBar */}
      <Toolbar sx={{ px: 2 }}>
        <Typography variant="h6" noWrap component="div">
          MUI AppShell
        </Typography>
      </Toolbar>

      <Divider />

      <List sx={{ px: 1 }}>
        {navItems.map((item) => {
          const selected =
            location.pathname === item.to ||
            (item.to !== '/' && location.pathname.startsWith(item.to + '/'));

          return (
            <ListItemButton
              key={item.to}
              component={NavLink}
              to={item.to}
              selected={selected}
              onClick={() => setMobileOpen(false)}
              sx={{
                borderRadius: 2,
                mx: 1,
                my: 0.5,
              }}
            >
              <ListItemIcon sx={{ minWidth: 44 }}>{item.icon}</ListItemIcon>
              <ListItemText primary={item.label} />
            </ListItemButton>
          );
        })}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <AppBar
        position="fixed"
        sx={{
          // Ensure AppBar stays above the Drawer
          zIndex: (t) => t.zIndex.drawer + 1,

          // When the drawer is permanent (desktop), offset the AppBar
          width: { md: `calc(100% - ${drawerWidth}px)` },
          ml: { md: `${drawerWidth}px` },
        }}
      >
        <Toolbar>
          {!isDesktop && (
            <IconButton
              color="inherit"
              edge="start"
              onClick={handleDrawerToggle}
              aria-label="Open navigation menu"
              sx={{ mr: 2 }}
            >
              <MenuIcon />
            </IconButton>
          )}

          <Typography variant="h6" noWrap component="div">
            {navItems.find((x) => location.pathname.startsWith(x.to))?.label ??
              'App'}
          </Typography>

          <Box sx={{ flexGrow: 1 }} />

          <ModeToggle />
          <UserMenu />
        </Toolbar>
      </AppBar>

      {/* Navigation area */}
      <Box
        component="nav"
        aria-label="Primary navigation"
        sx={{
          width: { md: drawerWidth },
          flexShrink: { md: 0 },
        }}
      >
        {/* Mobile: temporary drawer */}
        <Drawer
          variant="temporary"
          open={!isDesktop && mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true,
          }}
          sx={{
            display: { xs: 'block', md: 'none' },
            '& .MuiDrawer-paper': {
              width: drawerWidth,
              boxSizing: 'border-box',
            },
          }}
        >
          {drawerContent}
        </Drawer>

        {/* Desktop: permanent drawer */}
        <Drawer
          variant="permanent"
          open
          sx={{
            display: { xs: 'none', md: 'block' },
            '& .MuiDrawer-paper': {
              width: drawerWidth,
              boxSizing: 'border-box',
            },
          }}
        >
          {drawerContent}
        </Drawer>
      </Box>

      {/* Main content */}
      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { md: `calc(100% - ${drawerWidth}px)` },
          p: 3,
        }}
      >
        {/* Offset so content isn't hidden under fixed AppBar */}
        <Toolbar />

        <Outlet />
      </Box>
    </Box>
  );
}
```

Notes tying this to official guidance:

* **Responsive drawer** pattern (`temporary` for small, `permanent` for wide screens) is explicitly recommended in the Drawer docs. ([MUI][9])
* **Fixed AppBar offset** with an extra `<Toolbar />` is a recommended approach in the AppBar docs. ([MUI][8])

---

## Pages + routing (`Outlet`)

### Create pages

#### `src/pages/DashboardPage.tsx`

```tsx
// src/pages/DashboardPage.tsx
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';

export default function DashboardPage() {
  return (
    <Stack spacing={2}>
      <Typography variant="h4">Dashboard</Typography>

      <Paper sx={{ p: 2 }}>
        <Typography>
          This is your dashboard content area. Replace this with your widgets,
          charts, or tables.
        </Typography>
      </Paper>
    </Stack>
  );
}
```

#### `src/pages/ReportsPage.tsx`

```tsx
// src/pages/ReportsPage.tsx
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import Button from '@mui/material/Button';

export default function ReportsPage() {
  return (
    <Stack spacing={2}>
      <Typography variant="h4">Reports</Typography>

      <Paper sx={{ p: 2 }}>
        <Typography sx={{ mb: 2 }}>
          Imagine a table, filters, export actions, etc.
        </Typography>
        <Button variant="contained">Generate report</Button>
      </Paper>
    </Stack>
  );
}
```

#### `src/pages/SettingsPage.tsx`

```tsx
// src/pages/SettingsPage.tsx
import Typography from '@mui/material/Typography';
import Paper from '@mui/material/Paper';
import Stack from '@mui/material/Stack';
import Switch from '@mui/material/Switch';
import FormControlLabel from '@mui/material/FormControlLabel';

export default function SettingsPage() {
  return (
    <Stack spacing={2}>
      <Typography variant="h4">Settings</Typography>

      <Paper sx={{ p: 2 }}>
        <FormControlLabel control={<Switch defaultChecked />} label="Example setting" />
      </Paper>
    </Stack>
  );
}
```

#### `src/pages/NotFoundPage.tsx`

```tsx
// src/pages/NotFoundPage.tsx
import Typography from '@mui/material/Typography';

export default function NotFoundPage() {
  return <Typography variant="h5">404 — Not Found</Typography>;
}
```

### Wire routes in `src/App.tsx`

```tsx
// src/App.tsx
import { Navigate, Route, Routes } from 'react-router-dom';

import { AppShell } from './layout/AppShell';

import DashboardPage from './pages/DashboardPage';
import ReportsPage from './pages/ReportsPage';
import SettingsPage from './pages/SettingsPage';
import NotFoundPage from './pages/NotFoundPage';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<AppShell />}>
        <Route index element={<Navigate to="/dashboard" replace />} />
        <Route path="dashboard" element={<DashboardPage />} />
        <Route path="reports" element={<ReportsPage />} />
        <Route path="settings" element={<SettingsPage />} />
      </Route>

      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
}
```

---

## Run it

```bash
npm run dev
```

Open the printed local URL.

What to check:

* On mobile width: hamburger button opens a temporary drawer
* On desktop width: permanent drawer is pinned
* Theme toggle cycles: `system → light → dark → system`
* Route changes render inside the content area (`<Outlet />`)

---

## Optional upgrades (mini drawer, SSR/Next.js, Grid v2 notes)

### 1) Mini variant drawer (collapsible)

MUI supports “mini variant” drawers (collapsed rail → expanded) as an official pattern. ([MUI][9])
If you want that, the easiest approach is:

* Keep `variant="permanent"`
* Animate the drawer paper width between `collapsedWidth` and `drawerWidth`
* Change `ListItemText` opacity/display when collapsed
* Add an expand/collapse icon button near the top

### 2) SSR / Next.js and avoiding theme “flash”

If you use SSR and manually toggle schemes (class/data selector), MUI recommends adding `InitColorSchemeScript` before the app content to prevent flickering during hydration. ([MUI][10])
For Next.js App Router specifically, follow MUI’s official integration guide. ([MUI][11])

### 3) Grid v2 note (MUI v7)

If you’re using MUI Grid in your pages: in MUI v7, **GridLegacy** is deprecated in favor of the improved Grid (Grid v2). ([MUI][12])
This doesn’t affect the AppShell directly (we mostly used `Box`, `Toolbar`, `Drawer`), but it matters for dashboards and responsive page layouts.

---

## Next steps you can add easily

* **Breadcrumbs** in the AppBar
* **Search** in the AppBar
* **Route-driven page titles** + `<Helmet />` or metadata
* **Auth guard routes** (redirect unauthenticated users)
* **Role-based navigation** (filter `navItems` by user permissions)
* **Persist Drawer collapsed state** (localStorage)

[1]: https://mui.com/versions/ "Material UI Versions"
[2]: https://ja.react.dev/versions?utm_source=chatgpt.com "React のバージョン – React"
[3]: https://reactrouter.com/?utm_source=chatgpt.com "React Router Official Documentation"
[4]: https://mui.com/material-ui/getting-started/installation/ "Installation - Material UI"
[5]: https://mui.com/material-ui/customization/dark-mode/ "Dark mode - Material UI"
[6]: https://mui.com/material-ui/customization/css-theme-variables/usage/ "CSS theme variables - Usage - Material UI"
[7]: https://mui.com/material-ui/react-css-baseline/ "CSS Baseline - Material UI"
[8]: https://mui.com/material-ui/react-app-bar/ "App Bar React component - Material UI"
[9]: https://mui.com/material-ui/react-drawer/ "React Drawer component - Material UI"
[10]: https://mui.com/material-ui/customization/css-theme-variables/configuration/ "CSS theme variables - Configuration - Material UI"
[11]: https://mui.com/material-ui/integrations/nextjs/?utm_source=chatgpt.com "Next.js integration - Material UI"
[12]: https://mui.com/material-ui/migration/upgrade-to-grid-v2/?utm_source=chatgpt.com "Upgrade to Grid v2 - Material UI"

{% endraw %}
