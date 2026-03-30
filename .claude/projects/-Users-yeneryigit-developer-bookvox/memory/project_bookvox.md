---
name: BookVox Project Overview
description: iOS audiobook app - PDF to AI-powered TTS, 52 Swift files, MVVM + SwiftData + Supabase + Railway TTS
type: project
---

BookVox iOS uygulamasi — PDF kitaplari yapay zeka seslendirmesiyle dinleme.

**Why:** Kullanicilarin herhangi bir PDF'i farkli ses tonlariyla (storyteller, academic, intimate, dramatic) dinleyebilmesi.

**How to apply:**
- Tech stack: SwiftUI + SwiftData + @Observable MVVM, iOS 17+
- Backend: Supabase (auth/DB/storage) + Railway Python FastAPI (TTS Worker) + Grok TTS API + Cloudflare R2
- 52 Swift dosya: 7 model, 12 servis, 5 viewmodel, 24 view, 1 intent, 3 utility
- Supabase entegrasyonu henuz placeholder — gercek credentials gerekli
- Xcode projesi xcodegen ile olusturuluyor (project.yml)
- SPM dependency: supabase-swift v2.0.0+
