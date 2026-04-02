# Components (99)

ViewComponent and Phlex components available for reuse.
Use `rails_get_component_catalog(component:"Name")` for full details.

- **Alert** (phlex)
  props: variant:nil
- **AlertDescription** (phlex)
- **AlertDialog** (phlex)
  props: open:false
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
  props: article, liked:nil
- **Articles::ArticleUser** (phlex)
  props: article
- **Articles::Form** (phlex)
  props: article
- **Avatar** (phlex)
  props: size::md
- **AvatarFallback** (phlex)
- **AvatarImage** (phlex)
  props: src, alt:""
- **Badge** (phlex)
  props: variant::primary, size::md
- **Base** (phlex)
- **Base** (phlex)
- **Breadcrumb** (phlex)
- **BreadcrumbEllipsis** (phlex)
- **BreadcrumbItem** (phlex)
- **BreadcrumbLink** (phlex)
  props: href:"#"
- **BreadcrumbList** (phlex)
- **BreadcrumbPage** (phlex)
- **BreadcrumbSeparator** (phlex)
- **Button** (phlex)
  props: type::button, variant::primary, size::md, icon:false
- **Card** (phlex)
- **CardContent** (phlex)
- **CardDescription** (phlex)
- **CardFooter** (phlex)
- **CardHeader** (phlex)
- **CardTitle** (phlex)
- **Carousel** (phlex)
  props: orientation::horizontal, options:{}
- **CarouselContent** (phlex)
- **CarouselItem** (phlex)
- **CarouselNext** (phlex)
- **CarouselPrevious** (phlex)
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
  props: open:false
- **DialogContent** (phlex)
  props: size::md
- **DialogDescription** (phlex)
- **DialogFooter** (phlex)
- **DialogHeader** (phlex)
- **DialogMiddle** (phlex)
- **DialogTitle** (phlex)
- **DialogTrigger** (phlex)
- **Flash** (phlex)
- **Form** (phlex)
- **FormField** (phlex)
- **FormFieldError** (phlex)
- **FormFieldHint** (phlex)
- **FormFieldLabel** (phlex)
- **Heading** (phlex)
  props: level:nil, as:nil, size:nil
- **Home::Article** (phlex)
  props: article, liked:nil
- **InlineCode** (phlex)
- **InlineLink** (phlex)
  props: href
- **Input** (phlex)
  props: type::string
- **Layout** (phlex)
- **Likes::Button** (phlex)
  props: likeable, liked:nil
- **Link** (phlex)
  props: href:"#", variant::link, size::md, icon:false
- **LoginRequired** (phlex)
  props: title:"로그인이 필요합니다", message:"댓글을 작성하거나 대화에 참여하려면 로그인이 필요합니다."
- **Pagination** (phlex)
- **Pagination** (phlex)
  props: pagy
- **PaginationContent** (phlex)
- **PaginationEllipsis** (phlex)
- **PaginationItem** (phlex)
  props: href:"#", active:false
- **Posts::PostCard** (phlex)
  props: post, depth:0, liked:nil
- **Posts::PostForm** (phlex)
  props: post:Post.new
- **Posts::PostThread** (phlex)
  props: post, liked:nil
- **Posts::ReplyForm** (phlex)
  props: parent_post
- **PushNotifications::PromptModal** (phlex)
- **RadioButton** (phlex)
- **RecentCommentsSidebar** (phlex)
  props: recent_comments
- **Select** (phlex)
- **SelectContent** (phlex)
- **SelectGroup** (phlex)
- **SelectInput** (phlex)
- **SelectItem** (phlex)
  props: value:nil
- **SelectLabel** (phlex)
- **SelectTrigger** (phlex)
- **SelectValue** (phlex)
  props: placeholder:nil
- **Separator** (phlex)
  props: as::div, orientation::horizontal, decorative:true
- **SetDarkMode** (phlex)
- **SetLightMode** (phlex)
- **TagsSidebar** (phlex)
  props: tags, current_tag:nil
- **Text** (phlex)
  props: as:"p", size:"3", weight:"regular"
- **Textarea** (phlex)
  props: rows:4
- **ThemeToggle** (phlex)
- **TypographyBlockquote** (phlex)
- **Users::Form** (phlex)
  props: user
- **Users::PwdForm** (phlex)
  props: user
- **Users::User** (phlex)
  props: user