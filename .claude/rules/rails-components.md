---
paths:
  - "app/components/**/*.rb"
  - "app/views/components/**"
---

# Components (140)

ViewComponent and Phlex components available for reuse.
Use `rails_get_component_catalog(component:"Name")` for full details.

- **Alert** (phlex)
  props: variant:nil, attrs
- **AlertDescription** (phlex)
- **AlertDialog** (phlex)
  props: open:false, attrs
- **AlertDialogAction** (phlex)
- **AlertDialogCancel** (phlex)
- **AlertDialogContent** (phlex)
  slots: container
- **AlertDialogDescription** (phlex)
- **AlertDialogFooter** (phlex)
- **AlertDialogHeader** (phlex)
- **AlertDialogTitle** (phlex)
- **AlertDialogTrigger** (phlex)
- **AlertTitle** (phlex)
- **Articles::Article** (phlex)
  props: article, liked:nil, boosted:nil
- **Articles::ArticleUser** (phlex)
  props: article
- **Articles::Form** (phlex)
  props: article
- **Articles::GoogleSearch** (phlex)
  props: query:nil
- **Articles::SearchTabs** (phlex)
  props: source, search:nil
- **Avatar** (phlex)
  props: size::md, attrs
- **AvatarFallback** (phlex)
- **AvatarImage** (phlex)
  props: src, alt:"", attrs
- **Badge** (phlex)
  props: variant::primary, size::md, args
- **Base** (phlex)
  props: user_attrs
- **Base** (phlex)
- **Boosts::Button** (phlex)
  props: boostable, boosted:nil
- **Breadcrumb** (phlex)
- **BreadcrumbEllipsis** (phlex)
- **BreadcrumbItem** (phlex)
- **BreadcrumbLink** (phlex)
  props: href:"#", attrs
- **BreadcrumbList** (phlex)
- **BreadcrumbPage** (phlex)
- **BreadcrumbSeparator** (phlex)
- **Button** (phlex)
  props: type::button, variant::primary, size::md, icon:false, attrs
- **Card** (phlex)
- **CardContent** (phlex)
- **CardDescription** (phlex)
- **CardFooter** (phlex)
- **CardHeader** (phlex)
- **CardTitle** (phlex)
- **Carousel** (phlex)
  props: orientation::horizontal, options:{}, user_attrs
- **CarouselContent** (phlex)
- **CarouselItem** (phlex)
- **CarouselNext** (phlex)
- **CarouselPrevious** (phlex)
- **Chart** (phlex)
  props: options:{}, attrs
- **Checkbox** (phlex)
- **CheckboxGroup** (phlex)
- **Comments::Comment** (phlex)
  props: comment, article, depth:0, children:{}
- **Comments::CommentForm** (phlex)
  props: article, comment
- **Comments::CommentHeader** (phlex)
  props: comments
- **Comments::CommentReplyForm** (phlex)
  props: article, comment, parent_comment, visible:false
- **Comments::Comments** (phlex)
  props: article, comments
- **Dialog** (phlex)
  props: open:false, attrs
- **DialogContent** (phlex)
  props: size::md, attrs
- **DialogDescription** (phlex)
- **DialogFooter** (phlex)
- **DialogHeader** (phlex)
- **DialogMiddle** (phlex)
- **DialogTitle** (phlex)
- **DialogTrigger** (phlex)
- **DropdownMenu** (phlex)
  props: options:{}, attrs
- **DropdownMenuContent** (phlex)
- **DropdownMenuItem** (phlex)
  props: as::a, href:"#", attrs
- **DropdownMenuLabel** (phlex)
- **DropdownMenuSeparator** (phlex)
- **DropdownMenuTrigger** (phlex)
- **Flash** (phlex)
- **Form** (phlex)
- **FormField** (phlex)
- **FormFieldError** (phlex)
- **FormFieldHint** (phlex)
- **FormFieldLabel** (phlex)
- **Heading** (phlex)
  props: level:nil, as:nil, size:nil, attrs
- **Home::Article** (phlex)
  props: article, liked:nil, boosted:nil
- **Home::Feature** (phlex)
  props: articles, liked_article_ids:[], boosted_article_ids:[]
- **InlineCode** (phlex)
- **InlineLink** (phlex)
  props: href, attrs
- **Input** (phlex)
  props: type::string, attrs
- **Layout** (phlex)
- **Layout::AssetPreloads** (phlex)
  props: section
- **Layout::Footer** (phlex)
- **Layout::MetaTags** (phlex)
- **Layout::NavBar** (phlex)
- **Layout::StructuredData** (phlex)
- **Likes::Button** (phlex)
  props: likeable, liked:nil
- **Link** (phlex)
  props: href:"#", variant::link, size::md, icon:false, attrs
- **LoginRequired** (phlex)
  props: title:nil, message:nil
- **Mailers::Layout** (phlex)
  props: title, intro:nil, eyebrow:nil
- **OauthButton::Apple** (phlex)
  props: path, label
- **OauthButton::Github** (phlex)
  props: path, label
- **OauthButton::Google** (phlex)
  props: path, label
- **Pagination** (phlex)
  props: pagy
- **Pagination** (phlex)
- **PaginationContent** (phlex)
- **PaginationEllipsis** (phlex)
- **PaginationItem** (phlex)
  props: href:"#", active:false, attrs
- **Popover** (phlex)
  props: options:{}, attrs
- **PopoverContent** (phlex)
- **PopoverTrigger** (phlex)
- **Posts::BlogEditor** (phlex)
  props: post
- **Posts::PostCard** (phlex)
  props: post, depth:0, liked:nil, boosted:nil, booster:nil, show_actions:true, show_reply_badge:true
- **Posts::PostForm** (phlex)
  props: post:Post.new
- **Posts::PostThread** (phlex)
  props: post, liked:nil
- **Posts::ReplyForm** (phlex)
  props: parent_post
- **Profiles::ActivityTabs** (phlex)
  props: user, active_tab
- **Progress** (phlex)
  props: value:0, attrs
- **PushNotifications::PromptModal** (phlex)
- **RadioButton** (phlex)
- **RecentCommentsSidebar** (phlex)
  props: recent_comments
- **SearchSuggestion** (phlex)
  props: query
- **Select** (phlex)
- **SelectContent** (phlex)
  props: attrs
- **SelectGroup** (phlex)
- **SelectInput** (phlex)
- **SelectItem** (phlex)
  props: value:nil, attrs
- **SelectLabel** (phlex)
- **SelectTrigger** (phlex)
- **SelectValue** (phlex)
  props: placeholder:nil, attrs
- **Separator** (phlex)
  props: as::div, orientation::horizontal, decorative:true, attrs
- **SetDarkMode** (phlex)
- **SetLightMode** (phlex)
- **Switch** (phlex)
  props: include_hidden:true, checked_value:"1", unchecked_value:"0", attrs
- **Tabs** (phlex)
  props: default:nil, attrs
- **TabsContent** (phlex)
  props: value, attrs
- **TabsList** (phlex)
- **TabsTrigger** (phlex)
  props: value, attrs
- **TagsSidebar** (phlex)
  props: tags, current_tag:nil
- **Text** (phlex)
  props: as:"p", size:"3", weight:"regular", attrs
- **Textarea** (phlex)
  props: rows:4, attrs
- **ThemeToggle** (phlex)
- **TypographyBlockquote** (phlex)
- **UserAvatar** (phlex)
  props: user:nil, federails_actor:nil, name, size:"h-8 w-8", fallback_class:"bg-surface-muted text-accent-text ring-1 ring-inset ring-border-muted text-sm font-bold"
- **Users::Form** (phlex)
  props: user
- **Users::Form::Actions** (phlex)
  props: user
- **Users::Form::ErrorMessages** (phlex)
  props: user
- **Users::Form::Header** (phlex)
  props: user
- **Users::Form::NewFields** (phlex)
  props: form, user
- **Users::Form::PasswordFields** (phlex)
  props: form, user
- **Users::Form::PersistedFields** (phlex)
  props: form, user
- **Users::PwdForm** (phlex)
  props: user
- **Users::User** (phlex)
  props: user